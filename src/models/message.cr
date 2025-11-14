class Message
  include Lustra::Model

  belongs_to user : User, counter_cache: true

  primary_key

  column telegram_message_id : Int64
  column telegram_message_date : Int64
  column telegram_chat_id : Int64
  column telegram_chat_type : String
  column text : String?
  column location : PG::Geo::Point?

  timestamps

  def message : String
    text ||
      location.try { |l| Geo::Coord.new(l.y, l.x).to_s } ||
      ""
  end
end
