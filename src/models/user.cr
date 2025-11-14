class User
  include Lustra::Model

  has_many messages : Message

  primary_key

  column telegram_id : Int64
  column first_name : String
  column last_name : String?
  column username : String?
  column language_code : String?
  column messages_count : Int32

  timestamps
end
