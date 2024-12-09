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
  def list_teams_for(%User{} = user) do
    query =
      from t in Team,
        join: tm in TeamMember,
        on: tm.team_id == t.id,
        join: u in User,
        on: u.id == tm.user_id,
        where: u.id == ^user.id

    Repo.all(query)
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
  def create_team(attrs \\ %{}) do
    %Team{}
    |> Team.changeset(attrs)
    |> Repo.insert()
  end

  # Be able to get a Team
  def get_team_by_slug!(slug), do: Repo.get_by!(Team, slug: slug)
  def get_team!(id), do: Repo.get!(Team, id)

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

  # Add a user to a team
  def add_user_to_team(%Team{} = team, %User{} = user, role \\ "member") do
    %TeamMember{}
    |> TeamMember.changeset(%{team_id: team.id, user_id: user.id, role: role})
    |> Repo.insert()
  end

  # Remove a user from a team
  def remove_user_from_team(%TeamMember{} = team_member) do
    Repo.delete(team_member)
  end
end
