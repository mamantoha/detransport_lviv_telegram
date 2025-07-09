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
          stop_id = callback_data.sub("update_", "").to_i
          handle_update_routes(chat_id, stop_id)
        elsif callback_data.starts_with?("map_")
          stop_id = callback_data.sub("map_", "").to_i
          handle_show_on_map(chat_id, stop_id)
        elsif callback_data.starts_with?("route_")
          parts = callback_data.split("_")
          stop_id = parts[1].to_i
          route_id = parts[2].to_i
          handle_route_selection(chat_id, stop_id, route_id)
        elsif callback_data == "delete_message"
          handle_delete_message(chat_id)
        else
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
      if message = @callback_query.message
        bot.edit_message_text(
          chat_id: chat_id,
          message_id: message.message_id,
          text: routes_text(stop_id),
          parse_mode: "Markdown",
          reply_markup: update_keyboard(stop_id)
        )
      end
    end

    private def handle_show_on_map(chat_id : Int64, stop_id : Int32)
      stops = DetransportTelegram::Bot.stops
      if stop = stops.get_by_id(stop_id)
        coord = Geo::Coord.new(stop.latitude, stop.longitude)

        buttons = [
          [
            TelegramBot::InlineKeyboardButton.new(
              text: "🗑 #{I18n.translate("messages.delete_message")}",
              callback_data: "delete_message"
            ),
          ],
        ]
        keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

        bot.send_venue(
          chat_id,
          latitude: stop.latitude,
          longitude: stop.longitude,
          title: stop.full_name,
          address: "\n🧭 #{coord}",
          reply_markup: keyboard
        )
      end
    end

    private def handle_route_selection(chat_id : Int64, stop_id : Int32, route_id : Int32)
      lad_api = DetransportTelegram::LadAPI.new
      lad_routes = lad_api.show_routes(stop_id)

      if route = lad_routes.routes.find { |r| r.id == route_id }
        stops = DetransportTelegram::Bot.stops
        stop = stops.get_by_id(stop_id)
        stop_title = stop.try(&.full_name) || lad_routes.title

        text = String::Builder.build do |io|
          io << "🚏 `#{stop_title}`" << "\n"
          io << "#{route.transport_icon} `#{route.transport_name} #{route.title}`" << "\n"
          io << "📍 `#{route.direction_title}`" << "\n"
          io << "\n"
          io << "⏰ #{I18n.translate("messages.arrival_time")}: *#{route.time_left_formatted}*" << "\n"
          io << "📡 #{I18n.translate("messages.data_source")}: `#{route.time_source}`" << "\n"
          io << "\n"
          if route.has_gps?
            io << "📍 #{I18n.translate("messages.gps_enabled")}" << "\n"
          end
          if route.handicapped?
            io << "♿ #{I18n.translate("messages.accessible")}" << "\n"
          end
          if route.wifi?
            io << "📶 #{I18n.translate("messages.wifi_available")}" << "\n"
          end
        end.to_s

        buttons = [
          [
            TelegramBot::InlineKeyboardButton.new(
              text: "🌐 #{I18n.translate("messages.view_on_eway")}",
              url: "https://www.eway.in.ua/ua/cities/lviv/routes/#{route_id}"
            ),
          ],
          [
            TelegramBot::InlineKeyboardButton.new(
              text: "🗑 #{I18n.translate("messages.delete_message")}",
              callback_data: "delete_message"
            ),
          ],
        ]
        keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

        bot.send_message(chat_id, text, parse_mode: "Markdown", reply_markup: keyboard)
      end
    end

    private def handle_delete_message(chat_id : Int64)
      if message = @callback_query.message
        bot.delete_message(chat_id, message.message_id)
      end
    end

    private def update_keyboard(stop_id : Int32)
      lad_api = DetransportTelegram::LadAPI.new
      lad_routes = lad_api.show_routes(stop_id)

      buttons = [] of Array(TelegramBot::InlineKeyboardButton)

      routes = lad_routes.routes.sort_by(&.time_left.to_f)

      # Add route buttons
      routes.each_with_index do |route, index|
        button_text = "#{route.transport_icon} #{route.title} (#{route.direction_title}) - #{route.time_left_formatted}"
        callback_data = "route_#{stop_id}_#{route.id}"
        buttons << [TelegramBot::InlineKeyboardButton.new(text: button_text, callback_data: callback_data)]
      end

      # Add action buttons
      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🔄 #{I18n.translate("messages.update_routes")}",
          callback_data: "update_#{stop_id}"
        ),
        TelegramBot::InlineKeyboardButton.new(
          text: "🗺 #{I18n.translate("messages.show_stop_on_map")}",
          callback_data: "map_#{stop_id}"
        ),
      ]
      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🗑 #{I18n.translate("messages.delete_message")}",
          callback_data: "delete_message"
        ),
      ]

      TelegramBot::InlineKeyboardMarkup.new(buttons)
    end

    private def routes_text(stop_id : Int32)
      lad_api = DetransportTelegram::LadAPI.new
      lad_routes = lad_api.show_routes(stop_id)

      stops = DetransportTelegram::Bot.stops
      stop = stops.get_by_id(stop_id)
      stop_title = stop.try(&.full_name) || lad_routes.title

      current_time = Time.local(Time::Location.load("Europe/Kyiv"))
      formatted_time = current_time.to_s("%Y-%m-%d %H:%M:%S")

      String::Builder.build do |io|
        io << "🚏 `#{stop_title}`" << "\n"
        io << "\n"
        io << "_#{I18n.translate("messages.last_updated")}: #{formatted_time}_"
      end.to_s
    end
  end
end
