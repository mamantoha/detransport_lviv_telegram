class User < ApplicationRecord
  with_timestamps

  mapping(
    id: Primary64,
    telegram_id: Int64,
    first_name: String,
    last_name: String?,
    username: String?,
    language_code: String?,
    created_at: Time?,
    updated_at: Time?,
  )
end
