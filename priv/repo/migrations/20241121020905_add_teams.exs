defmodule PmTool.Repo.Migrations.AddTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string, null: false
      add :owner_id, references(:users), null: false
      add :slug, :string, null: false
      timestamps()
    end

    create unique_index(:teams, [:slug])

    create table(:team_members) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"
      timestamps()
    end

    create unique_index(:team_members, [:team_id, :user_id])
    create index(:team_members, [:user_id])
    create index(:team_members, [:team_id])
  end
end
