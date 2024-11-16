defmodule PmTool.Repo.Migrations.AddStagesToTasks do
  use Ecto.Migration

  def change do
    create table(:stages) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :stage, :string, null: false, default: "icebox"
      timestamps()
    end
    index(:stagees, [:task_id])

    alter table(:tasks) do
      add :current_stage_id, references(:stages)
    end
  end
end
