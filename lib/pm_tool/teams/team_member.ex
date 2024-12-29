defmodule PmTool.Teams.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset
  @roles ["owner", "admin", "member"]

  schema "team_members" do
    field :role, :string
    field :name, :string
    field :email, :string

    belongs_to :team, PmTool.Teams.Team
    belongs_to :user, PmTool.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:role, :team_id, :user_id, :name, :email])
    |> validate_required([:team_id, :email, :role])
    |> unique_constraint([:team_id, :email], name: :team_members_team_id_email_index)
    |> validate_inclusion(:role, @roles)
  end
end
