require "./handlers/*"

module DetransportTelegram
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super(ENV["BOT_NAME"], ENV["BOT_TOKEN"])
    end

    protected def logger : Logger
      DetransportTelegram.logger
    end

    def handle(message : TelegramBot::Message)
      handle_with(message, DetransportTelegram::MessageHandler)
    end

    def handle(callback_query : TelegramBot::CallbackQuery)
      handle_with(callback_query, DetransportTelegram::CallbackQueryHandler)
    end

    private def handle_with(obj, klass)
      begin
        time = Time.utc
        logger.info "> #{obj.class.name} #{obj.to_json}"

        klass.new(obj, self).handle

        logger.debug("Handled #{obj.class.name} in #{Time.utc - time}")
        return true
      rescue e
        logger.error(e.inspect_with_backtrace)
        return false
      end
    end
  end
end
