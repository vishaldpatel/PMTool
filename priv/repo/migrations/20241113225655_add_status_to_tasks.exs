defmodule PmTool.Repo.Migrations.AddStatusToTasks do
  use Ecto.Migration

  def change do
    create table(:task_status) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "unstarted"
      timestamps()
    end
    index(:task_status, [:task_id])

    alter table(:tasks) do
      add :current_status_id, references(:task_status)
    end
  end
end
