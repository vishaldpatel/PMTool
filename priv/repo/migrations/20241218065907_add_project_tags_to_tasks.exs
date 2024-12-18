defmodule PmTool.Repo.Migrations.AddProjectTagsToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :project_tags, {:array, :string}
    end
  end
end
