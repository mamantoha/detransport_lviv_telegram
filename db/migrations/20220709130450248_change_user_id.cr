class ChangeUserId < Jennifer::Migration::Base
  def up
    change_table(:users) do |t|
      t.change_column(:id, :bigint)
    end
  end

  def down
    change_table(:users) do |t|
      t.change_column(:id, :integer)
    end
  end
end
