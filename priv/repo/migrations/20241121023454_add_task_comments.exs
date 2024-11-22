defmodule PmTool.Repo.Migrations.AddTaskComments do
  use Ecto.Migration

  def change do
    create table (:task_comments) do
      add :user_id, references(:users)
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :info, :string, null: false

      timestamps()
    end

    create index(:task_comments, [:user_id])
    create index(:task_comments, [:task_id])
  end
end
