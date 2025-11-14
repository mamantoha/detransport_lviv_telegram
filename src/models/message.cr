class Message
  include Lustra::Model

  belongs_to user : User

  primary_key

  column telegram_message_id : Int64
  column telegram_message_date : Int64
  column telegram_chat_id : Int64
  column telegram_chat_type : String
  column text : String

  timestamps
end
