class CreateMessages
  include Lustra::Migration

  def change(dir)
    dir.up do
      create_table(:messages) do |t|
        t.column :telegram_message_id, :bigint, null: false
        t.column :telegram_message_date, :bigint, null: false
        t.column :telegram_chat_id, :bigint, null: false
        t.column :telegram_chat_type, :string, null: false
        t.column :text, :text, null: true
        t.column :location, :point, null: true

        t.references to: "users", name: "user_id", on_delete: "cascade", null: false, primary: true

        t.timestamps

        t.index ["user_id", "telegram_chat_id"], using: :btree
      end
    end

    dir.down do
      execute("DROP TABLE messages")
    end
  end
end
