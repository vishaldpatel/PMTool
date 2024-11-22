defmodule PmTool.Teams.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset
  @roles ["owner", "admin", "member"]

  schema "team_members" do
    field :role, :string

    belongs_to :team, PmTool.Teams.Team
    belongs_to :user, PmTool.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:role, :team_id, :user_id])
    |> validate_required([:team_id, :user_id])
    |> unique_constraint([:team_id, :user_id], name: :team_members_team_id_user_id_index)
    |> validate_inclusion(:role, @roles)
  end
end
