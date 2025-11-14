class AddMessagesCountToUsers
  include Lustra::Migration

  def change(dir)
    dir.up do
      add_column "users", "messages_count", :int, nullable: false, default: "0"
    end

    dir.down do
      add_column "users", "messages_count", :int
    end
  end
end
