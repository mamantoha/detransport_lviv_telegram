require "logger"
require "json"
require "telegram_bot"
require "dotenv"
require "haversine"
require "crest"
require "jaro_winkler"
require "i18n"

# Require "ifrit" (which is dependency of "jennifer")  before raven.
# Otherwise you've found a bug in the Crystal compiler.
require "../config/initializers/database"

require "raven"

require "./detransport_telegram/*"

require "./models/*"

Dotenv.load

I18n::Backend::Yaml.embed(["#{__DIR__}/locales"])
I18n.init

I18n.default_locale = "uk"

Raven.configure do |config|
  config.async = true
  config.connect_timeout = 5.seconds
  config.read_timeout = 5.seconds
end

module DetransportTelegram
  VERSION = "0.1.0"

  def self.run
    bot = DetransportTelegram::Bot.new
    logger.info "DetransportTelegram started."
    bot.polling
  end
end

DetransportTelegram.run
