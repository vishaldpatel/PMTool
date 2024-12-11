defmodule PmTool.Repo.Migrations.TasksProjectsM2mRelationship do
  use Ecto.Migration

  def change do
    # Remove project_id from tasks
    # Remove index from tasks for project_id
    drop index(:tasks, [:project_id])
    
    alter table(:tasks) do
      remove :project_id
    end

    create table(:project_tasks) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
    end

    create unique_index(:project_tasks, [:project_id, :task_id])
    create index(:project_tasks, [:project_id])
    create index(:project_tasks, [:task_id])

  end
end
