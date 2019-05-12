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
        handle_text(message_text)
      elsif message_location = message.location
        handle_location(message_location)
      end
    end

    private def handle_text(text : String)
      if text.starts_with?("/")
        handle_commands(text)
      else
        handle_similar_stops(text)
      end
    end

    private def handle_commands(text : String)
      if text =~ /^\/(help|start)/
        handle_help
      end
    end

    private def handle_similar_stops(text : String)
      text = I18n.translate("messages.select_stop")

      simital_stops = stops.similar_to(text.not_nil!)

      buttons = build_keyboard_for_simital_stops(simital_stops)
      keyboard = TelegramBot::InlineKeyboardMarkup.new(buttons)

      bot.send_message(chat_id, text, reply_markup: keyboard)
    end

    private def handle_location(location : TelegramBot::Location)
      text = I18n.translate("messages.nearest_stops")

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
        text = "🚏 #{stop.name} - #{distance.to_meters.to_i} m"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end

    private def build_keyboard_for_simital_stops(stops : Array(DetransportTelegram::Stop))
      stops.reduce([] of Array(TelegramBot::InlineKeyboardButton)) do |arry, stop|
        text = "🚏 #{stop.name}"
        arry << [TelegramBot::InlineKeyboardButton.new(text: text, callback_data: "#{stop.id}")]
      end
    end

    private def stops
      stops_json = File.open("#{__DIR__}/../data/lviv_stops.json")

      DetransportTelegram::Stops.new(DetransportTelegram::StopsIterator.from_json(stops_json))
    end
  end
end
