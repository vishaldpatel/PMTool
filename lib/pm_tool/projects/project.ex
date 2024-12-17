defmodule PmTool.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  schema "projects" do
    field :name, :string
    field :description, :string
    field :slug, :string
    field :label, :string
    field :labels, {:array, :string}
    
    belongs_to :creator, PmTool.Accounts.User
    many_to_many :teams, PmTool.Teams.Team, join_through: PmTool.Projects.TeamProject
    many_to_many :tasks, PmTool.Tasks.Task, join_through: PmTool.Projects.ProjectTask

    timestamps()
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name, :description, :creator_id, :label, :labels])
    |> validate_required([:name])
    |> slugify()
    |> unique_constraint(:slug)
    |> unique_constraint(:label)
  end
end
