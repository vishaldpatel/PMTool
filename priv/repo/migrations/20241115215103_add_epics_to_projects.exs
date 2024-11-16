defmodule PmTool.Repo.Migrations.AddEpicsToProjects do
  use Ecto.Migration

  def change do
    create table(:epics) do
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :string

      # Each task should have a unique hash to be used for the url_string
      add :url_hash, :string, null: false

      timestamps()
    end
    index(:epics, [:project_id])
    unique_index(:tasks, [:url_hash])

    alter table(:tasks) do
      add :epic_id, references(:epics, on_delete: :nilify_all)
    end
  end
end
