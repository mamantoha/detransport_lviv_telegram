{% if compare_versions(Crystal::VERSION, "0.35.0-0") >= 0 %}
  alias CallStack = Exception::CallStack
{% end %}

require "log"
require "json"
require "telegram_bot"
require "dotenv"
require "haversine"
require "geo"
require "crest"
require "fuzzy_match"
require "i18n"
require "humanize_time"
require "./detransport_telegram/*"

require "../config/config"
require "./models/*"

I18n.config.loaders << I18n::Loader::YAML.embed("#{__DIR__}/locales")
I18n.config.default_locale = "uk"
I18n.init

module DetransportTelegram
  VERSION = "0.1.0"

  Log = ::Log.for(self)
  Log.level = :debug

  log_file = File.new("#{__DIR__}/../log/telegram.log", "a")
  stdout = STDOUT

  writer = IO::MultiWriter.new(log_file, stdout)

  Log.backend = ::Log::IOBackend.new(writer)

  def self.run
    Dotenv.load

    bot = DetransportTelegram::Bot.new

    Log.info { "DetransportTelegram started." }

    commands = [
      TelegramBot::BotCommand.new(command: "help", description: "інформація про бота"),
      TelegramBot::BotCommand.new(command: "ping", description: "pong 🏓"),
      TelegramBot::BotCommand.new(command: "about", description: "🤖"),
    ]

    bot.set_my_commands(commands)

    bot.polling
  end
end

DetransportTelegram.run
