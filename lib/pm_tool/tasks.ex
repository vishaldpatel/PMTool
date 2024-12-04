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
      where: t.team_id == ^team.id and t.status != "done",
      order_by: [t.stage, t.task_order]
    Repo.all(query)
  end

  # Get all tasks for project
  def list_tasks_for(%Project{} = project) do
    query = from t in Task,
      where: t.project_id == ^project.id,
      order_by: [t.stage, t.task_order]
    Repo.all(query)
  end

  # Get all tasks for a user that are not "Done"
  def list_tasks_for(%User{} = user) do
    query = from t in Task,
      where: t.creator_id == ^user.id and is_nil(t.team_id),
      order_by: [t.stage, t.task_order]
    Repo.all(query)
  end

  def list_tasks_for(%Team{} = team, stage) do
    query = from t in Task,
      where: t.team_id == ^team.id and t.stage == ^stage,
      order_by: [t.task_order]
    Repo.all(query)
  end

  def list_tasks_for(%User{} = user, stage) do
    query = from t in Task,
      where: t.creator_id == ^user.id and t.stage == ^stage and is_nil(t.team_id),
      order_by: [t.task_order]
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

  def move_task_above(%Task{} = task, %Task{} = above_task) do
    prev_order = task.task_order
    new_order = above_task.task_order

    query = from t in Task,
      where: t.stage == ^above_task.stage
        and t.task_order >= ^new_order
    query = 
    if not is_nil(above_task.team_id) do
      where(query, [t], t.team_id == ^above_task.team_id)
    else
      where(query, [t], t.creator_id == ^above_task.creator_id)
    end

    query = 
      if task.stage == above_task.stage do
        where(query, [t], t.task_order <= ^prev_order)
      else
        query
      end
    Repo.update_all(query, [inc: [task_order: 1]])
    update_task(task, %{"task_order" => new_order, "stage" => above_task.stage})
  end

  def move_task_below(%Task{} = task, %Task{} = below_task) do
    new_order = below_task.task_order + 1

    query = from t in Task,
      where: t.stage == ^below_task.stage
        and t.task_order >= ^new_order
    query = 
    if not is_nil(below_task.team_id) do
      where(query, [t], t.team_id == ^below_task.team_id)
    else
      where(query, [t], t.creator_id == ^below_task.creator_id) 
    end
    Repo.update_all(query, [inc: [task_order: 1]])

    update_task(task, %{"task_order" => new_order, "stage" => below_task.stage})
  end

  def get_max_task_order_for(%User{} = creator, stage) do
    query = from t in Task,
      where: t.creator_id == ^creator.id and t.stage == ^stage,
      select: max(t.task_order)
    Repo.one(query)
  end

  def get_max_task_order_for(%Team{} = team, stage) do
    query = from t in Task,
      where: t.team_id == ^team.id and t.stage == ^stage,
      select: max(t.task_order)
    Repo.one(query)
  end

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
