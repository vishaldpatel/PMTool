defmodule PmTool.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :url_hash, :string, null: false
      add :url_slug, :string, null: false
      add :description, :string
      add :owner_id, references(:users, on_delete: :nothing)

      # Each project should have a unique hash to be used for the url_string
      unique_index(:projects, [:url_hash])

      timestamps()
    end
  end
end
