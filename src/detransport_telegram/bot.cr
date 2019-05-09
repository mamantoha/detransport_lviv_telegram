module DetransportTelegram
  class Bot < TelegramBot::Bot
    include TelegramBot::CmdHandler

    def initialize
      super(ENV["BOT_NAME"], ENV["BOT_TOKEN"])
    end

    def handle(message : TelegramBot::Message)
      DetransportTelegram::MessageHandler.new(message, self).handle
    end

    def handle(callback_query : TelegramBot::CallbackQuery)
      DetransportTelegram::CallbackQueryHandler.new(callback_query, self).handle
    end
  end
end
