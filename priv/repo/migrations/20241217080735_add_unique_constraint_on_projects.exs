defmodule PmTool.Repo.Migrations.AddUniqueConstraintOnProjects do
  use Ecto.Migration

  def change do
    create unique_index(:projects, [:tag])
  end
end
