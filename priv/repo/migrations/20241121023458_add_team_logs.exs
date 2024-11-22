defmodule PmTool.Repo.Migrations.AddTeamLogs do
  use Ecto.Migration

  def change do
    create table(:team_logs) do
      add :team_id, references(:teamss)
      add :user_id, references(:users, on_delete: :nilify_all)
      add :task_id, references(:tasks, on_delete: :nilify_all)
      add :name, :string, null: false
      add :action, :string, null: false

      timestamps()
    end

    create index(:team_logs, [:team_id])
    create index(:team_logs, [:task_id])
    create index(:team_logs, [:user_id])
  end
end
