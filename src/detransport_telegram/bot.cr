require "./handlers/*"

module DetransportTelegram
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super(Config.telegram_bot_name, Config.telegram_token)
    end

    def handle(message : TelegramBot::Message)
      handle_with(message, DetransportTelegram::MessageHandler)
    end

    def handle(callback_query : TelegramBot::CallbackQuery)
      handle_with(callback_query, DetransportTelegram::CallbackQueryHandler)
    end

    private def handle_with(obj, klass)
      time = Time.utc
      DetransportTelegram::Log.info { "> #{obj.class.name} #{obj.to_json}" }

      if user = load_user(obj)
        user.updated_at = Time.local(Jennifer::Config.local_time_zone)
        user.save
      end

      klass.new(obj, self).handle

      DetransportTelegram::Log.debug { "Handled #{obj.class.name} in #{Time.utc - time}" }
      true
    rescue e
      DetransportTelegram::Log.error { e.inspect_with_backtrace }
      false
    end

    private def load_user(msg) : User?
      if telegram_user = msg.from
        if user = User.where { _telegram_id == telegram_user.id }.first
          user
        else
          User.create(
            telegram_id: telegram_user.id,
            first_name: telegram_user.first_name,
            last_name: telegram_user.last_name,
            username: telegram_user.username,
            language_code: telegram_user.language_code
          )
        end
      end
    end

    def self.stops
      stops_json = File.open("#{__DIR__}/data/lviv_stops.json")

      DetransportTelegram::Stops.new(DetransportTelegram::StopsIterator.from_json(stops_json))
    end
  end
end
