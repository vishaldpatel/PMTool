defmodule PmTool.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo

  alias PmTool.Teams.Team
  alias PmTool.Teams.TeamMember
  alias PmTool.Accounts.User

  # Be able to find teams for which
  # the current uesr has a membership
  # and also load their role
  def list_teams(%User{} = user) do
    query =
      from t in Team,
        join: tm in TeamMember,
        on: tm.team_id == t.id,
        where: tm.email == ^user.email

    Repo.all(query)
    |> Repo.preload([:team_members, :owner])
  end

  # List team members for a team along with their roles
  def list_members_for(%Team{} = team) do
    query =
      from tm in TeamMember,
        join: u in User,
        on: u.id == tm.user_id,
        where: tm.team_id == ^team.id

    Repo.all(query)
  end

  # Be able to create a Team
  def create_team_for(%User{} = user, attrs \\ %{}) do
    result =
      %Team{}
      |> Team.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, team} ->
        case create_team_member(team, user, "owner") do
          {:ok, _} -> {:ok, team}
          {:error, changeset} -> {:error, changeset}
        end

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  # Be able to get a Team
  def get_team_by_slug!(slug), do: Repo.get_by!(Team, slug: slug) |> Repo.preload([:team_members])
  def get_team!(id), do: Repo.get!(Team, id) |> Repo.preload([:team_members])
  def get_team_member!(id), do: Repo.get!(TeamMember, id)

  # Be able to update a Team
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  # Be able to delete a Team
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  def update_team_member(%TeamMember{} = team_member, team_member_params) do
    team_member
    |> TeamMember.changeset(team_member_params)
    |> Repo.update()
  end

  # Add a user to a team
  def create_team_member(team_member_params) do
    %TeamMember{}
    |> TeamMember.changeset(team_member_params)
    |> Repo.insert()
  end

  def create_team_member(%Team{} = team, %User{} = user, role \\ "member") do
    %TeamMember{}
    |> TeamMember.changeset(%{
      team_id: team.id,
      user_id: user.id,
      role: role,
      email: user.email,
      name: user.name
    })
    |> Repo.insert()
  end

  # Remove a user from a team
  def remove_team_member(%TeamMember{} = team_member) do
    Repo.delete(team_member)
  end
end
