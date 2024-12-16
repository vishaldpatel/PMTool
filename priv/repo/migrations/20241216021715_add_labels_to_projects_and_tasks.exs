defmodule PmTool.Repo.Migrations.AddLabelsToProjectsAndTasks do
  use Ecto.Migration

  def change do
    create table(:labels) do
      add :type, :string, null: false
      add :name, :string, null: false
      add :color, :string, null: false
      timestamps()
    end

    create unique_index(:labels, [:type, :name])

    alter table(:projects) do
      add :label_id, references(:labels)
    end

    create index(:projects, [:label_id])

    create table(:project_labels) do
      add :project_id, references(:projects), null: false
      add :label_id, references(:labels), null: false
    end

    create unique_index(:project_labels, [:project_id, :label_id])

    create table(:task_labels) do
      add :task_id, references(:tasks), null: false
      add :label_id, references(:labels), null: false
    end

    create unique_index(:task_labels, [:task_id, :label_id])
  end
end
