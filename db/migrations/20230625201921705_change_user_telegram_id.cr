class ChangeUserTelegramId < Jennifer::Migration::Base
  def up
    change_table(:users) do |t|
      t.change_column(:telegram_id, :bigint)
    end
  end

  def down
    change_table(:users) do |t|
      t.change_column(:telegram_id, :integer)
    end
  end
end
