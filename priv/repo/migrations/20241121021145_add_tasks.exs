defmodule PmTool.Repo.Migrations.AddTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :name, :string, null: false
      add :description, :string
      add :stage, :string, null: false, default: "backlog"
      add :status, :string, null: false, default: "unstarted"
      add :slug, :string, null: false

      add :creator_id, references(:users), null: false
      add :owner_id, references(:users)
      add :team_id, references(:teams), null: false

      timestamps()
    end

    create unique_index(:tasks, [:slug])
    create index(:tasks, [:team_id])
    create index(:tasks, [:team_id, :stage])
    create index(:tasks, [:team_id, :status])
  end
end
