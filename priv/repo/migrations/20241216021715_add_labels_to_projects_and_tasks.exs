defmodule PmTool.Repo.Migrations.AddLabelsToProjectsAndTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :tags, {:array, :string}
    end

    alter table(:projects) do
      add :tags, {:array, :string}
      add :tag, :string
    end
  end
end
