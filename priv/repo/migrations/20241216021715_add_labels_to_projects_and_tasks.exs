defmodule PmTool.Repo.Migrations.AddLabelsToProjectsAndTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :labels, {:array, :string}
    end

    alter table(:projects) do
      add :labels, {:array, :string}
      add :label, :string
    end
  end
end
