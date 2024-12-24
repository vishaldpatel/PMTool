defmodule PmTool.Repo.Migrations.RemoveProjectTasks do
  use Ecto.Migration

  def change do
    drop table(:project_tasks)
  end
end
