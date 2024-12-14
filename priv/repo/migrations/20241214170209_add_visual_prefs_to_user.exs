defmodule PmTool.Repo.Migrations.AddVisualPrefsToUser do
  use Ecto.Migration

  def change do
    create table(:user_preferences) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :preferences, :map, null: false
      timestamps()
    end

    create unique_index(:user_preferences, [:user_id])
  end
end
