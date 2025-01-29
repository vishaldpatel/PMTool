defmodule PmTool.Repo.Migrations.RenameTeamLogsToChangelogs do
  use Ecto.Migration

  def change do
    rename table(:team_logs), to: table(:changelog)
  end
end
