require "jennifer"
require "jennifer/adapter/postgres"

Jennifer::Config.read("config/database.yml", :development)

log_file = File.new("#{__DIR__}/../../log/jennifer.log", "a")
stdout = STDOUT

writer = IO::MultiWriter.new(log_file, stdout)

::Log.setup("db", :debug, ::Log::IOBackend.new(writer))
