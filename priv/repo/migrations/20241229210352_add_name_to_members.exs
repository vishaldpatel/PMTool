defmodule PmTool.Repo.Migrations.AddNameToMembers do
  use Ecto.Migration

  def change do
    alter table(:team_members) do
      add :name, :string
      add :email, :string
    end

    # Drop constraint on team_id, user_id
    drop unique_index(:team_members, [:team_id, :user_id])

    # Add constraint on team_id, email
    create unique_index(:team_members, [:team_id, :email])
  end
end
