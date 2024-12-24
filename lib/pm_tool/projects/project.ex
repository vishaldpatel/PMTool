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
    
    belongs_to :creator, PmTool.Accounts.User
    many_to_many :teams, PmTool.Teams.Team, join_through: PmTool.Projects.TeamProject

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :creator_id, :tag, :tags])
    |> validate_required([:name, :creator_id, :tag])
    |> slugify()
    |> unique_constraint(:slug)
    |> unique_constraint(:tag)
  end
end
