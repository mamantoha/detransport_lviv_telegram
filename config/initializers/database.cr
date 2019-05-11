require "jennifer"
require "jennifer/adapter/postgres"

Jennifer::Config.read("config/database.yml", :development)
