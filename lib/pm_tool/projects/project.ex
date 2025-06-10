defmodule PmTool.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  schema "projects" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :tag, :string
    field :tags, {:array, :string}
    field :archived, :boolean

    belongs_to :creator, PmTool.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :creator_id, :tag, :tags, :archived])
    |> validate_required([:name, :creator_id, :tag])
    |> slugify()
    |> unique_constraint(:slug)
    |> unique_constraint(:tag)
  end
end
