$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "mongodb_session_store/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "mongodb_session_store"
  s.version     = MongodbSessionStore::VERSION
  s.authors     = ["Christopher Fuller"]
  s.email       = ["git@chrisfuller.me"]
  s.homepage    = "http://github.com/chrisfuller/mongodb_session_store"
  s.summary     = "Stores Rails sessions in a MongoDB collection with configurable options including garbage-collection.\nUse with or without a MongoDB object mapper (ODM).\n\n(keywords: mongo db mongodb database rails session sessions)"
  s.description = "Stores Rails sessions in a MongoDB collection with configurable options including garbage-collection.\nUse with or without a MongoDB object mapper (ODM).\n\n(keywords: mongo db mongodb database rails session sessions)"

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", ">= 3.1"
  s.add_dependency "mongo"
end
