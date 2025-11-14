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

      # Delete the user's message after processing
      bot.delete_message(chat_id, message.message_id)
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
      when /^\/city/
        handle_city
      when /^\/ping/
        bot.reply(message, "🏓")
      when /^\/admin:(\w+)/
        return unless authorize_admin!(message)

        case $1
        when "users"
          handle_users(message)
        when "messages"
          handle_messages(message)
        end
      else
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

    private def handle_city
      coordinates = {49.8397, 24.0297}
      sun = SunTimes::SunTime.new(coordinates)
      location = Time::Location.load("Europe/Kyiv")
      date = Time.local(location)

      events = sun.events(date, location)

      text = <<-HEREDOC
        #{I18n.t("city.current_date")}: #{date.to_s("%Y-%m-%d")}
        #{I18n.t("city.current_time")}: #{date.to_s("%H:%M:%S")}
        #{I18n.t("city.sunrise")}: #{events[:sunrise].try(&.to_s("%H:%M:%S"))}
        #{I18n.t("city.sunset")}: #{events[:sunset].try(&.to_s("%H:%M:%S"))}
        HEREDOC

      buttons = [
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

    def authorize_admin!(message : TelegramBot::Message) : Bool
      if telegram_user = message.from
        unless telegram_user.id == Config.admin_telegram_id
          bot.reply(message, "⛔ #{I18n.translate("admin.access_denied")}")

          return false
        end

        true
      else
        false
      end
    end

    private def handle_users(message : TelegramBot::Message)
      users = User.query.order_by(updated_at: :desc)

      text = String::Builder.build do |io|
        io << "👥 *#{I18n.translate("admin.users_list_title")}* (#{users.size} #{I18n.translate("admin.users_total")})"
        io << "\n\n"

        users.each_with_index do |user, index|
          io << "#{index + 1}. "
          io << "ID: `#{user.telegram_id}` "
          if user.first_name
            io << "#{user.first_name}"
          end
          if user.last_name
            io << " #{user.last_name}"
          end
          if user.username
            io << " (@#{user.username})"
          end
          io << "\n"
          updated_at = user.updated_at.try { |t| t.in(Config.timezone).to_s("%Y-%m-%d %H:%M") }
          io << "   📅 #{I18n.translate("admin.updated")}: `#{updated_at}`\n"
          if user.language_code
            io << "   🌐 #{I18n.translate("admin.lang")}: `#{user.language_code}`\n"
          end
          io << "\n"
        end
      end.to_s

      buttons = [
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

    private def handle_messages(message : TelegramBot::Message)
      messages = Message.query
        .with_user
        .order_by(created_at: :desc)
        .limit(10)

      text = String::Builder.build do |io|
        io << "💬 *#{I18n.translate("admin.messages_list_title")}* (#{messages.size})"
        io << "\n\n"

        messages.each_with_index do |msg, index|
          user = msg.user
          io << "#{index + 1}. "

          # User info
          if user
            if user.first_name
              io << "#{user.first_name}"
            end
            if user.last_name
              io << " #{user.last_name}"
            end
            if user.username
              io << " (@#{user.username})"
            end
            io << " (ID: `#{user.telegram_id}`)"
          else
            io << "Unknown User"
          end

          io << "\n"

          # Message content (truncate if too long)
          message_text = msg.text.size > 100 ? "#{msg.text[0..97]}..." : msg.text
          io << "   💬 `#{message_text}`\n"

          # Timestamp
          if created_at = msg.created_at
            formatted_time = created_at.in(Config.timezone).to_s("%Y-%m-%d %H:%M:%S")
            io << "   🕐 #{formatted_time}\n"
          end

          io << "\n"
        end

        if messages.empty?
          io << "_No messages found._"
        end
      end.to_s

      buttons = [
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
