defmodule PmTool.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members) do
      # user_id is a foreign key from users table
      add :user_id, references(:users, on_delete: :delete_all)
      # project_id is a foreign key from projects table
      add :project_id, references(:projects, on_delete: :delete_all)

      # Projects should have only one listing per member.
      unique_index(:members, [:user_id, :project_id])

      timestamps()
    end
  end
end
