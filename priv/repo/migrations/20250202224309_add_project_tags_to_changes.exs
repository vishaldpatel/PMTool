defmodule PmTool.Repo.Migrations.AddProjectTagsToChanges do
  use Ecto.Migration

  def change do
    alter table(:changes) do
      add :project_tags, {:array, :string}
    end
  end
end
