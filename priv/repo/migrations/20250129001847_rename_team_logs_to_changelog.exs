defmodule PmTool.Repo.Migrations.RenameTeamLogsToChangelogs do
  use Ecto.Migration

  def change do
    drop index("team_logs", [:team_id])
    drop index("team_logs", [:user_id])

    alter table(:team_logs) do
      remove :user_id
      remove :team_id
      add :team_member_id, references(:team_members)
      add :description, :string, null: false
      add :user_id, references(:users)
      add :team_id, references(:teams, on_delete: :nilify_all)
    end

    create index(:team_logs, [:user_id])
    create index(:team_logs, [:team_id])
    rename table(:team_logs), to: table(:changes)
  end
end
