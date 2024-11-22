defmodule PmTool.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  schema "projects" do
    field :name, :string
    field :description, :string
    field :slug, :string

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description])
    |> validate_required([:name])
    |> slugify()
    |> unique_constraint(:slug)
  end

end
