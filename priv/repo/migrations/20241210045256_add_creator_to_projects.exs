defmodule PmTool.Repo.Migrations.AddCreatorToProjects do
  use Ecto.Migration

  def change do
    alter table(:projects) do
      add :creator_id, references(:users), null: false
    end

    create index(:projects, [:creator_id])
  end
end
