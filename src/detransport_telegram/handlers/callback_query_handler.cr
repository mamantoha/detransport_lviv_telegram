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

        callback_data = @callback_query.data

        return unless callback_data

        if callback_data.starts_with?("update_")
          # Handle update request
          stop_id = callback_data.sub("update_", "").to_i
          handle_update_routes(chat_id, stop_id)
        else
          # Handle regular stop selection
          stop_id = callback_data.to_i
          handle_stop_selection(chat_id, stop_id)
        end
      end
    end

    private def handle_stop_selection(chat_id : Int64, stop_id : Int32)
      bot.send_message(
        chat_id: chat_id,
        text: routes_text(stop_id),
        parse_mode: "Markdown",
        reply_markup: update_keyboard(stop_id)
      )
    end

    private def handle_update_routes(chat_id : Int64, stop_id : Int32)
      # Find the message to update
      if message = @callback_query.message
        # Update the existing message with fresh data
        bot.edit_message_text(
          chat_id: chat_id,
          message_id: message.message_id,
          text: routes_text(stop_id),
          parse_mode: "Markdown",
          reply_markup: update_keyboard(stop_id)
        )
      end
    end

    private def update_keyboard(stop_id : Int32)
      buttons = [
        [
          TelegramBot::InlineKeyboardButton.new(
            text: "🔄 #{I18n.translate("messages.update_routes")}",
            callback_data: "update_#{stop_id}"
          ),
        ],
      ]
      TelegramBot::InlineKeyboardMarkup.new(buttons)
    end

    private def routes_text(stop_id : Int32)
      lad_api = DetransportTelegram::LadAPI.new
      lad_routes = lad_api.show_routes(stop_id)

      stops = DetransportTelegram::Bot.stops
      stop = stops.get_by_id(stop_id)
      stop_title = stop.try(&.full_name) || lad_routes.title

      routes = lad_routes.routes.reduce([] of String) do |arry, route|
        arry << route.full_title
      end

      current_time = Time.local(Time::Location.load("Europe/Kyiv"))
      formatted_time = current_time.to_s("%Y-%m-%d %H:%M:%S")

      String::Builder.build do |io|
        io << "🚏 `#{stop_title}`" << "\n"
        io << "#{I18n.translate("messages.show_stop_on_map")}: /#{stop_id}" << "\n"
        io << "\n"
        routes.each { |el| io << el << "\n" }
        io << "\n"
        io << "_#{I18n.translate("messages.last_updated")}: #{formatted_time}_"
      end.to_s
    end
  end
end
