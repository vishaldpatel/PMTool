defmodule PmTool.Repo.Migrations.DropUserIdNotNullFromTeamMembers do
  use Ecto.Migration

  def change do
    drop index(:team_members, [:user_id])

    alter table(:team_members) do
      remove :user_id
      add :user_id, references(:users, on_delete: :nilify_all)
    end
  end
end
