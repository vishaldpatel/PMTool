defmodule PmTool.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  schema "teams" do
    field :name, :string
    field :slug, :string

    belongs_to :owner, PmTool.Accounts.User, foreign_key: :owner_id
    has_many :team_members, PmTool.Teams.TeamMember
    many_to_many :projects, PmTool.Projects.Project, join_through: PmTool.Projects.TeamProject

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :owner_id])
    |> validate_required([:name, :owner_id])
    |> slugify()
    |> unique_constraint(:slug)
  end
end
