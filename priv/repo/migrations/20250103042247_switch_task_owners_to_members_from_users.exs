defmodule PmTool.Repo.Migrations.SwitchTaskOwnersToMembersFromUsers do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :owner_id
      add :owner_id, references(:team_members, on_delete: :nilify_all)
    end
  end
end
