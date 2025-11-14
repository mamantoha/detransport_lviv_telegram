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
        user.touch

        if obj.is_a?(TelegramBot::Message)
          store_message(obj, user)
        end
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
        User.query.find_or_create({telegram_id: telegram_user.id}) do |user|
          user.telegram_id = telegram_user.id
          user.first_name = telegram_user.first_name
          user.last_name = telegram_user.last_name
          user.username = telegram_user.username
          user.language_code = telegram_user.language_code
        end
      end
    end

    private def store_message(telegram_message : TelegramBot::Message, user : User)
      if text = telegram_message.text
        # Don't store admin commands from admin user
        if user.telegram_id == Config.admin_telegram_id && text.starts_with?("/admin:")
          return
        end

        user.messages.create(
          telegram_message_id: telegram_message.message_id,
          telegram_message_date: telegram_message.date,
          telegram_chat_id: telegram_message.chat.id,
          telegram_chat_type: telegram_message.chat.type,
          text: text
        )

        DetransportTelegram::Log.debug { "Stored message #{telegram_message.message_id} from user #{user.telegram_id}" }
      elsif location = telegram_message.location
        user.messages.create(
          telegram_message_id: telegram_message.message_id,
          telegram_message_date: telegram_message.date,
          telegram_chat_id: telegram_message.chat.id,
          telegram_chat_type: telegram_message.chat.type,
          location: PG::Geo::Point.new(location.longitude, location.latitude)
        )

        DetransportTelegram::Log.debug { "Stored location message #{telegram_message.message_id} from user #{user.telegram_id}" }
      end
    rescue e
      DetransportTelegram::Log.error { "Failed to store message: #{e.message}" }
    end

    @@stops : DetransportTelegram::Stops?

    def self.stops
      @@stops ||= begin
        DetransportTelegram::Log.debug { "Loading stops from JSON..." }
        stops_json = File.open("#{__DIR__}/data/lviv_stops.json")
        DetransportTelegram::Stops.new(DetransportTelegram::StopsIterator.from_json(stops_json))
      end
    end
  end
end
