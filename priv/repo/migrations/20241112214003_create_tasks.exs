defmodule PmTool.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :project_id, :integer, null: false
      add :creator_id, :integer, null: false
      add :owner_id, :integer
      add :name, :string, null: false
      add :description, :string

      # Each task should have a unique hash to be used for the url_string
      add :url_hash, :string, null: false

      # Each task should have a unique hash to be used for the url_string
      unique_index(:tasks, [:url_hash])
      index(:tasks, [:project_id])

      timestamps()
    end
  end
end
