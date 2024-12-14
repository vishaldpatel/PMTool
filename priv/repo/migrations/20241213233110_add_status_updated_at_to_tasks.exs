defmodule PmTool.Repo.Migrations.AddStatusUpdatedAtToTasks do
  use Ecto.Migration

  def up do
    alter table(:tasks) do
      add :status_updated_at, :utc_datetime
    end

    # Updated existing entries to the updated_at column
    execute("UPDATE tasks SET status_updated_at = updated_at")
  end

  def down do
    alter table(:tasks) do
      remove :status_updated_at
    end
  end
end
