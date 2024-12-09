defmodule PmTool.Repo.Migrations.AddTaskBlockers do
  use Ecto.Migration

  def change do
    create table(:blockers) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :description, :string, null: false
      add :done, :boolean, null: false, default: false

      timestamps()
    end

    create index(:blockers, [:task_id])
  end
end
