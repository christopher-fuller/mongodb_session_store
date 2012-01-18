require 'mongodb_session_store/mongodb_session_store'

module MongodbSessionStore
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/mongodb_session_store_tasks.rake'
    end
  end
end
