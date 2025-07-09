module DetransportTelegram
  class MessageHandler
    getter message : TelegramBot::Message
    getter bot : DetransportTelegram::Bot
    getter chat_id : Int64

    def initialize(@message, @bot)
      @chat_id = @message.chat.id
    end

    def handle
      if message_text = message.text
        handle_text(message, message_text)
      elsif message_location = message.location
        handle_location(message_location)
      end
    end

    private def handle_text(message, text : String)
      if text.starts_with?("/")
        handle_commands(message, text)
      else
        handle_similar_stops(text)
      end
    end

    private def handle_commands(message, text : String)
      case text
      when /^\/(help|start)/
        handle_help
      when /^\/about/
        handle_about
      when /^\/ping/
        bot.reply(message, "🏓")
      else
        nil
      end
    end

    private def swap_keyboard_layout_from_latin_to_ua(text : String)
      chars_hash = {'q' => 'й', 'w' => 'ц', 'e' => 'у', 'r' => 'к', 't' => 'е', 'y' => 'н', 'u' => 'г', 'i' => 'ш', 'o' => 'щ', 'p' => 'з', '[' => 'х', ']' => 'ї', '\\' => 'ґ', 'a' => 'ф', 's' => 'і', 'd' => 'в', 'f' => 'а', 'g' => 'п', 'h' => 'р', 'j' => 'о', 'k' => 'л', 'l' => 'д', ';' => 'ж', '\'' => 'є', 'z' => 'я', 'x' => 'ч', 'c' => 'с', 'v' => 'м', 'b' => 'и', 'n' => 'т', 'm' => 'ь', ',' => 'б', '.' => 'ю', '/' => '.', 'Q' => 'Й', 'W' => 'Ц', 'E' => 'У', 'R' => 'К', 'T' => 'Е', 'Y' => 'Н', 'U' => 'Г', 'I' => 'Ш', 'O' => 'Щ', 'P' => 'З', '{' => 'Х', '}' => 'Ї', '|' => 'Ґ', 'A' => 'Ф', 'S' => 'І', 'D' => 'В', 'F' => 'А', 'G' => 'П', 'H' => 'Р', 'J' => 'О', 'K' => 'Л', 'L' => 'Д', ':' => 'Ж', '"' => 'Є', 'Z' => 'Я', 'X' => 'Ч', 'C' => 'С', 'V' => 'М', 'B' => 'И', 'N' => 'Т', 'M' => 'Ь', '<' => 'Б', '>' => 'Ю', '?' => ','}
      text.gsub(chars_hash)
    end

    private def handle_similar_stops(stop : String)
      stops = DetransportTelegram::Bot.stops

      stop = swap_keyboard_layout_from_latin_to_ua(stop)
      similar_stops = stops.similar_to(stop)

      if similar_stops.empty?
        text = "⚠️ #{I18n.translate("messages.stops_not_found")}"
        bot.send_message(chat_id, text)
      else
        buttons = build_keyboard_for_similar_stops(similar_stops)

        buttons << [
          TelegramBot::InlineKeyboardButton.new(
            text: "🗑 #{I18n.translate("messages.delete_message")}",
            callback_data: "delete_message"
          ),
        ]

        keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

        text = I18n.translate("messages.select_stop")
        bot.send_message(chat_id, text, reply_markup: keyboard)
      end
    end

    private def handle_about
      text = <<-HEREDOC
      Build with Crystal #{Crystal::VERSION}
      Build date: #{Time.parse_rfc2822(Config.date).to_s("%Y-%m-%d %H:%M:%S %:z")}
      HEREDOC

      bot.send_message(chat_id, text, parse_mode: "Markdown")
    end

    private def handle_location(location : TelegramBot::Location)
      text = I18n.translate("messages.nearest_stops")

      stops = DetransportTelegram::Bot.stops
      nearest_stops = stops.nearest_to(location.latitude, location.longitude)

      buttons = build_keyboard_for_nearest_stops(nearest_stops, location)

      buttons << [
        TelegramBot::InlineKeyboardButton.new(
          text: "🗑 #{I18n.translate("messages.delete_message")}",
          callback_data: "delete_message"
        ),
      ]

      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, reply_markup: keyboard)
    end

    private def handle_help
      text = I18n.translate("messages.help")

      buttons = [
        [
          TelegramBot::KeyboardButton.new(
            "📍 #{I18n.translate("messages.share_location")}",
            request_contact: false,
            request_location: true
          ),
        ],
      ]

      keyboard = TelegramBot::ReplyKeyboardMarkup.new(buttons, resize_keyboard: true)

      bot.send_message(chat_id, text, reply_markup: keyboard, parse_mode: "Markdown")
    end

    private def build_keyboard_for_nearest_stops(stops : Array(DetransportTelegram::Stop), location : TelegramBot::Location)
      stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        distance = Haversine.distance(stop.latitude, stop.longitude, location.latitude, location.longitude)
        text = "🚏 #{stop.full_name} - #{distance.to_meters.to_i} m"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end

    private def build_keyboard_for_similar_stops(stops : Array(DetransportTelegram::Stop))
      stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        text = "🚏 #{stop.full_name}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end
  end
end
