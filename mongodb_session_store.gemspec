$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mongodb_session_store/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mongodb_session_store"
  s.version     = MongodbSessionStore::VERSION
  s.authors     = ["Chris Fuller"]
  s.email       = ["git@chrisfuller.me"]
  s.homepage    = "http://github.com/chrisfuller/mongodb_session_store"
  s.summary     = "Stores Rails sessions in a MongoDB collection. A MongoDB object mapper (ODM) is not required and the MongoDB collection name and key names are customizable."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.1.3"
  s.add_dependency "mongo"
end
