defmodule PmTool.Repo.Migrations.AddProjects do
  use Ecto.Migration

  def change do

    create table(:projects) do
      add :name, :string, null: false
      add :description, :string
      add :slug, :string, null: false
      timestamps()
    end

    create unique_index(:projects, [:slug])

    create table(:team_projects) do
      add :team_id, references(:teams, on_delete: :delete_all), null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
    end

    create unique_index(:team_projects, [:team_id, :project_id])
    create index(:team_projects, [:team_id])
    create index(:team_projects, [:project_id])

    alter table(:tasks) do
      add :project_id, references(:projects)
    end

    create index(:tasks, [:project_id])
  end
end
