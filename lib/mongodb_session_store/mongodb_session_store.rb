require 'mongo'

module ActionDispatch
  module Session
    class MongodbSessionStore < AbstractStore
      
      class Session
        
        class << self
          
          def drop_collection
            coll.drop
          end
          
          def find_or_create(sid)
            if expiration > 0
              coll.ensure_index([['updated_at', Mongo::ASCENDING]])
              coll.remove(:updated_at => { :$lte => Time.now - expiration })
            end
            hash = { sid_key => sid }
            new(coll.find_one(hash) || hash)
          end
          
          def coll
            MongodbSessionStore.db.collection(MongodbSessionStore.coll)
          end
          
          def sid_key
            MongodbSessionStore.sid_key
          end
          
          def data_key
            MongodbSessionStore.data_key
          end
          
          def expiration
            MongodbSessionStore.expiration
          end
          
        end
        
        def initialize(options = {})
          @_id        = options['_id']        if options['_id']
          @created_at = options['created_at'] if options['created_at']
          @updated_at = options['updated_at'] if options['updated_at']
          @sid        = options[sid_key]      if options[sid_key]
          @data       = options[data_key]     || BSON::Binary.new(Marshal.dump({}))
        end
        
        def data
          Marshal.load(StringIO.new(@data.to_s))
        end
        
        def data=(data)
          @data = BSON::Binary.new(Marshal.dump(data))
        end
        
        def save
          unless destroyed?
            @_id        ||= BSON::ObjectId.new
            @created_at ||= Time.now
            @updated_at   = Time.now
            coll.save(
              :_id        => @_id,
              :created_at => @created_at,
              :updated_at => @updated_at,
              sid_key     => @sid,
              data_key    => @data
            )
          end
        end
        
        def destroy
          unless destroyed?
            coll.remove('_id' => @_id) if @_id
            freeze
            @destroyed = true
          end
        end
        
        private
        
        def coll
          self.class.coll
        end
        
        def sid_key
          self.class.sid_key
        end
        
        def data_key
          self.class.data_key
        end
        
        def destroyed?
          @destroyed
        end
        
      end
      
      SESSION_RECORD_KEY      = 'rack.session.record'.freeze
      ENV_SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY
      
      cattr_reader :db, :coll, :sid_key, :data_key, :expiration
      
      def initialize(app, options = {})
        
        @@db         =   options[:database]
        @@coll       = ( options[:collection]         || 'sessions'     ).to_s
        @@sid_key    = ( options[:session_id_key]     || 'session_id'   ).to_s
        @@data_key   = ( options[:session_data_key]   || 'session_data' ).to_s
        @@expiration = ( options[:session_expiration] || 0              ).to_i
        
        @@db = @@db.call if @@db.is_a?(Proc)
        
        unless @@db.is_a?(Mongo::DB)
          raise_exception "Must provide one Mongo::DB instance in config/initializers/session_store.rb"
        end
        
        invalid_keys = ['_id', 'created_at', 'updated_at']
        
        if (invalid_keys + [@@data_key]).include?(@@sid_key)
          raise_exception "Invalid :session_id_key => #{@@sid_key}"
        end
        
        if (invalid_keys + [@@sid_key]).include?(@@data_key)
          raise_exception "Invalid :session_data_key => #{@@data_key}"
        end
        
        super
        
      end
      
      private
      
      def raise_exception(msg)
        class_name = self.class.name.split('::').last
        raise "#{class_name} [ERROR] #{msg}"
      end
      
      def get_session(env, sid)
        Base.silence do
          sid ||= generate_sid
          session = get_session_model(env, sid)
          [sid, session.data]
        end
      end
      
      def set_session(env, sid, data, options)
        Base.silence do
          session = get_session_model(env, sid)
          session.data = data
          session.save ? sid : false
        end
      end
      
      def destroy_session(env, sid, options)
        Base.silence do
          get_session_model(env, sid).destroy
          env[SESSION_RECORD_KEY] = nil
          generate_sid unless options[:drop]
        end
      end
      
      def get_session_model(env, sid)
        if env[ENV_SESSION_OPTIONS_KEY][:id].nil?
          env[SESSION_RECORD_KEY] = Session.find_or_create(sid)
        else
          env[SESSION_RECORD_KEY] ||= Session.find_or_create(sid)
        end
      end
      
    end
  end
end
