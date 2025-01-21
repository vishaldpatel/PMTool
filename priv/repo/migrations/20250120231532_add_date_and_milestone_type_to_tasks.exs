defmodule PmTool.Repo.Migrations.AddDateAndMilestoneTypeToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :due_date, :date
      add :is_milestone, :boolean, default: false
    end
  end
end
