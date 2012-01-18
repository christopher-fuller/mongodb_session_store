namespace :db do
  namespace :mongo do
    namespace :sessions do
      desc 'Drops the MongoDB collection used for storing the Rails sessions for the current Rails.env (USE WITH CAUTION)'
      task :clear => :environment do
        ActionDispatch::Session::MongodbSessionStore::Session.drop_collection
      end
    end
  end
end
