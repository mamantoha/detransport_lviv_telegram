module DetransportTelegram
  class CallbackQueryHandler
    getter callback_query : TelegramBot::CallbackQuery
    getter bot : DetransportTelegram::Bot
    getter chat_id : Int64?

    def initialize(@callback_query, @bot)
      if message = callback_query.message
        @chat_id = message.chat.id
      end
    end

    def handle
      if chat_id = @chat_id
        bot.answer_callback_query(@callback_query.id, cache_time: 1)

        stop_id = @callback_query.data

        keyboard = TelegramBot::ReplyKeyboardRemove.new
        bot.send_message(chat_id, routes_text(stop_id), parse_mode: "Markdown", reply_markup: keyboard)
      end
    end

    private def routes_text(stop_id)
      lad_api = DetransportTelegram::LadAPI.new

      lad_routes = lad_api.show_routes(stop_id)

      routes = lad_routes.routes.reduce([] of String) do |arry, route|
        arry << route.full_title
      end

      text = String::Builder.build do |io|
        io << "🚏 `#{lad_routes.title}`" << "\n"
        io << "\n"
        routes.each { |el| io << el << "\n" }
      end.to_s
    end
  end
end
