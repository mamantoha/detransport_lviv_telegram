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
      if text =~ /^\/(help|start)/
        handle_help
      elsif text =~ /^\/ping/
        bot.reply(message, "🏓")
      end
    end

    private def swap_keyboard_layout_from_latin_to_ua(text : String)
      chars_hash = {'q' => 'й', 'w' => 'ц', 'e' => 'у', 'r' => 'к', 't' => 'е', 'y' => 'н', 'u' => 'г', 'i' => 'ш', 'o' => 'щ', 'p' => 'з', '[' => 'х', ']' => 'ї', '\\' => 'ґ', 'a' => 'ф', 's' => 'і', 'd' => 'в', 'f' => 'а', 'g' => 'п', 'h' => 'р', 'j' => 'о', 'k' => 'л', 'l' => 'д', ';' => 'ж', '\'' => 'є', 'z' => 'я', 'x' => 'ч', 'c' => 'с', 'v' => 'м', 'b' => 'и', 'n' => 'т', 'm' => 'ь', ',' => 'б', '.' => 'ю', '/' => '.', 'Q' => 'Й', 'W' => 'Ц', 'E' => 'У', 'R' => 'К', 'T' => 'Е', 'Y' => 'Н', 'U' => 'Г', 'I' => 'Ш', 'O' => 'Щ', 'P' => 'З', '{' => 'Х', '}' => 'Ї', '|' => 'Ґ', 'A' => 'Ф', 'S' => 'І', 'D' => 'В', 'F' => 'А', 'G' => 'П', 'H' => 'Р', 'J' => 'О', 'K' => 'Л', 'L' => 'Д', ':' => 'Ж', '"' => 'Є', 'Z' => 'Я', 'X' => 'Ч', 'C' => 'С', 'V' => 'М', 'B' => 'И', 'N' => 'Т', 'M' => 'Ь', '<' => 'Б', '>' => 'Ю', '?' => ','}
      text.gsub(chars_hash)
    end

    private def handle_similar_stops(stop : String)
      text = I18n.translate("messages.select_stop")
      stop = swap_keyboard_layout_from_latin_to_ua(stop)

      stops = DetransportTelegram::Bot.stops
      simital_stops = stops.similar_to(stop)

      buttons = build_keyboard_for_simital_stops(simital_stops)
      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, reply_markup: keyboard)
    end

    private def handle_location(location : TelegramBot::Location)
      text = I18n.translate("messages.nearest_stops")

      stops = DetransportTelegram::Bot.stops
      nearest_stops = stops.nearest_to(location.latitude, location.longitude)

      buttons = build_keyboard_for_nearest_stops(nearest_stops, location)
      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, reply_markup: keyboard)
    end

    private def handle_help
      text = I18n.translate("messages.help")

      buttons = [
        [
          TelegramBot::KeyboardButton.new(I18n.translate("messages.share_location"), request_contact: false, request_location: true),
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

    private def build_keyboard_for_simital_stops(stops : Array(DetransportTelegram::Stop))
      stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        text = "🚏 #{stop.full_name}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end
  end
end
