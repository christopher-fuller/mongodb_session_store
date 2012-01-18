require 'mongo'

module ActionDispatch
  module Session
    class MongodbSessionStore < AbstractStore
      
      class Session
        
        class << self
          
          def drop_collection
            coll.drop
          end
          
          def find_or_create_session(sid)
            hash = { sid_key => sid }
            new(coll.find_one(hash) || hash)
          end
          
          def db
            @db ||= MongodbSessionStore.db
          end
          
          def coll
            @coll ||= db.collection(MongodbSessionStore.coll)
          end
          
          def sid_key
            @sid_key ||= MongodbSessionStore.sid_key
          end
          
          def data_key
            @data_key ||= MongodbSessionStore.data_key
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
            @persisted = true
          end
        end
        
        def destroy
          unless destroyed?
            coll.remove('_id' => @_id) if persisted?
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
          
          def persisted?
            @persisted
          end
          
          def destroyed?
            @destroyed
          end
          
      end
      
      SESSION_RECORD_KEY      = 'rack.session.record'.freeze
      ENV_SESSION_OPTIONS_KEY = Rack::Session::Abstract::ENV_SESSION_OPTIONS_KEY
      
      cattr_reader :db, :coll, :sid_key, :data_key
      
      def initialize(app, options = {})
        
        @@db       =   options[:database]
        @@coll     = ( options[:collection]       || 'sessions'     ).to_s
        @@sid_key  = ( options[:session_id_key]   || 'session_id'   ).to_s
        @@data_key = ( options[:session_data_key] || 'session_data' ).to_s
        
        class_name = self.class.name.split('::').last
        
        unless @@db.is_a?(Mongo::DB)
          message = []
          message << "#{class_name} [ERROR] Must provide one Mongo::DB in config/initializers/session_store.rb as in these examples:"
          message << "AppName::Application.config.session_store :mongodb_session_store, :database => MongoMapper.database"
          message << "AppName::Application.config.session_store :mongodb_session_store, :database => Mongoid.database"
          message << "AppName::Application.config.session_store :mongodb_session_store, :database => Mongo::Connection.new.db('db_name')"
          raise message.join("\n")
        end
        
        invalid_keys = ['_id', 'created_at', 'updated_at']
        
        if (invalid_keys + [@@data_key]).include?(@@sid_key)
          raise "#{class_name} [ERROR] Invalid :session_id_key => #{@@sid_key}"
        end
        
        if (invalid_keys + [@@sid_key]).include?(@@data_key)
          raise "#{class_name} [ERROR] Invalid :session_data_key => #{@@data_key}"
        end
        
        super
        
      end
      
      private
        
        def get_session(env, sid)
          sid ||= generate_sid
          session = get_session_model(env, sid)
          [sid, session.data]
        end
        
        def set_session(env, sid, data, options)
          session = get_session_model(env, sid)
          session.data = data
          session.save ? sid : false
        end
        
        def destroy_session(env, sid, options)
          get_session_model(env, sid).destroy
          env[SESSION_RECORD_KEY] = nil
          generate_sid # TODO: determine if 'generate_sid' is really needed here, or remove
        end
        
        def get_session_model(env, sid)
          if env[ENV_SESSION_OPTIONS_KEY][:id].nil?
            env[SESSION_RECORD_KEY] = find_or_create_session(sid)
          else
            env[SESSION_RECORD_KEY] ||= find_or_create_session(sid)
          end
        end
        
        def find_or_create_session(sid)
          Session.find_or_create_session(sid)
        end
        
    end
  end
end