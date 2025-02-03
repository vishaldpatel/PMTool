defmodule PmTool.Teams do
  @moduledoc """
  The Teams context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo

  alias PmTool.Teams.Team
  alias PmTool.Teams.TeamMember
  alias PmTool.Accounts.User
  alias PmTool.Teams.Change
  alias PmTool.Tasks
  alias PmTool.Tasks.Task

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

  def list_changes(%User{} = user, team, task_slugs) do
    user_or_team_changes =
      case is_nil(team) do
        true -> list_changes(user)
        false -> list_changes(team)
      end

    task_changes =
      Tasks.get_tasks_for_slugs!(task_slugs)
      |> Enum.map(& &1.id)
      |> list_changes()
      |> Enum.group_by(& &1.task_id)

    {user_or_team_changes, task_changes}
  end

  def list_changes(%Team{} = team) do
    Repo.all(from c in Change, where: c.team_id == ^team.id, order_by: [desc: c.inserted_at])
  end

  def list_changes(%User{} = user) do
    user_teams =
      Repo.all(from tm in TeamMember, where: tm.email == ^user.email, select: tm.team_id)

    Repo.all(
      from c in Change,
        where:
          c.user_id == ^user.id or
            c.team_id in ^user_teams,
        order_by: [desc: c.inserted_at]
    )
  end

  def list_changes(%Task{} = task) do
    Repo.all(from c in Change, where: c.task_id == ^task.id, order_by: [desc: c.inserted_at])
  end

  def list_changes(task_ids) do
    case task_ids do
      [] ->
        []

      _ ->
        Repo.all(
          from c in Change,
            where: c.task_id in ^task_ids,
            order_by: [asc: c.task_id, desc: c.inserted_at]
        )
    end
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

  def get_team_member!(%Team{} = team, %User{} = user),
    do: Repo.get_by(TeamMember, team_id: team.id, email: user.email)

  # Be able to update a Team
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  # Be able to delete a Team
  def delete_team(%Team{} = team, %User{} = current_user) do
    team
    |> Team.changeset(%{current_user_id: current_user.id})
    |> Repo.delete()
  end

  def update_team_member(%TeamMember{} = team_member, team_member_params) do
    changeset = TeamMember.changeset(team_member, team_member_params)

    if not is_nil(changeset) and changeset.valid? do
      Repo.update(changeset)
    else
      {:error, changeset}
    end
  end

  # Add a user to a team
  def create_team_member(team_member_params) do
    %TeamMember{}
    |> TeamMember.changeset(team_member_params)
    |> Repo.insert()
  end

  def create_team_member(%Team{} = team, %User{} = user, %User{} = current_user, role \\ "member") do
    %TeamMember{}
    |> TeamMember.changeset(%{
      team_id: team.id,
      user_id: user.id,
      role: role,
      email: user.email,
      name: user.name,
      current_user_id: current_user.id
    })
    |> Repo.insert()
  end

  # Remove a user from a team
  def remove_team_member(%TeamMember{} = team_member, %User{} = current_user) do
    team_member
    |> TeamMember.changeset(%{current_user_id: current_user.id})
    |> Repo.delete()
  end
end
