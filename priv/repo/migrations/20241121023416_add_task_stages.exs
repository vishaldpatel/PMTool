defmodule PmTool.Repo.Migrations.AddTaskStages do
  use Ecto.Migration

  def change do
    create table(:stages) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :stage, :string, null: false, default: "backlog"
      timestamps()
    end

    create index(:stages, [:task_id])
    create index(:stages, [:stage])

    alter table(:tasks) do
      add :current_stage_id, references(:stages)
    end

    create index(:tasks, [:current_stage_id])
  end
end
