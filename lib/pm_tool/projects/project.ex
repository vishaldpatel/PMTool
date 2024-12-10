defmodule PmTool.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  schema "projects" do
    field :name, :string
    field :description, :string
    field :slug, :string

    belongs_to :creator, PmTool.Accounts.User
    many_to_many :teams, PmTool.Projects.Team, join_through: PmTool.Projects.TeamProject
    has_many :tasks, PmTool.Tasks.Task

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :creator_id])
    |> validate_required([:name])
    |> slugify()
    |> unique_constraint(:slug)
  end
end
