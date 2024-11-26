defmodule PmTool.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo
  alias PmTool.Tasks.Task
  alias PmTool.Teams.Team
  alias PmTool.Accounts.User
  alias PmTool.Projects.Project

  # Get all tasks for team and stage
  def list_tasks_for(%Team{} = team) do
    query = from t in Task,
      where: t.team_id == ^team.id and t.status != "done"
    Repo.all(query)
  end

  # Get all tasks for project
  def list_tasks_for(%Project{} = project) do
    query = from t in Task,
      where: t.project_id == ^project.id
    Repo.all(query)
  end

  # Get all tasks for a user that are not "Done"
  def list_tasks_for(%User{} = user) do
    query = from t in Task,
      where: t.creator_id == ^user.id and is_nil(t.team_id)

    Repo.all(query)
  end 

  # Be able to create a Task
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  # Be able to get a Task
  def get_task!(id), do: Repo.get!(Task, id)

  # Get Task by slug
  def get_task_by_slug!(slug), do: Repo.get_by!(Task, slug: slug)

  # Be able to update a Task
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  # Be able to delete a Task
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  def delete_tasks_with_slugs(user, slugs) do
    query = from t in Task,
      where: t.creator_id == ^user.id and t.slug in ^slugs
    Repo.delete_all(query)
  end

end
