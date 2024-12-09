defmodule PmTool.Repo.Migrations.AddTaskEstimations do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :estimate, :integer, null: false, default: 1
    end
  end
end
