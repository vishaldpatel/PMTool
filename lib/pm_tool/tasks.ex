defmodule PmTool.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo
  alias PmTool.Tasks.Task
  alias PmTool.Teams.Team
  alias PmTool.Accounts.User
  alias PmTool.Projects
  alias PmTool.Projects.Project
  alias PmTool.Projects.ProjectTask

  # Get all tasks for project
  def list_tasks_for(%Project{} = project) do
    query =
      from t in Task,
        where: t.project_id == ^project.id,
        order_by: [t.stage, t.task_order]

    Repo.all(query)
  end

  def list_tasks(%User{} = user) do
    Repo.all(base_list_tasks_query(user))
    |> separate_tasks_into_stages()
  end

  def list_tasks(%User{} = user, project_slug) do
    project = Projects.get_project_by_slug!(project_slug)

    query =
      from t in base_list_tasks_query(user),
        join: pt in ProjectTask,
        on: pt.task_id == t.id and pt.project_id == ^project.id,
        order_by: [t.stage, t.task_order]

    unsorted_tasks = Repo.all(query)
    tasks = separate_tasks_into_stages(unsorted_tasks)
    tasks
  end

  defp base_list_tasks_query(user) do
    from t in Task,
      where: t.creator_id == ^user.id and is_nil(t.team_id),
      order_by: [fragment("CASE
        WHEN ? = 'Accepted' THEN 1
        WHEN ? = 'Closed' THEN 2
        WHEN ? = 'Delivered' THEN 3
        WHEN ? = 'Finished' THEN 4
        WHEN ? = 'Started' THEN 5
        WHEN ? = 'Rejected' THEN 6
        WHEN ? = 'Unstarted' THEN 7
        ELSE 8 END", t.status, t.status, t.status, t.status, t.status, t.status, t.status), t.task_order]

    # For an individual, we won't need more than 30 tasks
  end

  defp separate_tasks_into_stages(unsorted_tasks) do
    # Limit the results until the estimate adds up to 30
    [_now_estimate, tasks] =
      Enum.reduce_while(
        unsorted_tasks,
        [0, %{Now: [], Next: [], Done: [], Later: []}],
        fn task, acc ->
          [total_estimate, tasks] = acc
          last_period_end_date = Date.utc_today() |> Date.end_of_week() |> Date.add(-7)
          just_before_midnight =  Time.new!(23, 59, 59, 999_999)
          last_period_end = DateTime.new!(last_period_end_date, just_before_midnight, "Etc/UTC")
          status_updated_at = DateTime.from_naive!(task.status_updated_at, "Etc/UTC")
          cond do
            # If it was Accepted more than 7 days ago, then it is marked as Done
            Enum.member?(["Accepted", "Closed"], task.status) and (DateTime.compare(status_updated_at, last_period_end) == :lt)  ->
              {:cont, [total_estimate, %{tasks | Done: tasks[:Done] ++ [task]}]}

            task.stage == "Later" ->
              {:cont, [total_estimate, %{tasks | Later: tasks[:Later] ++ [task]}]}

            total_estimate + task.estimate <= 30 or task.status != "Unstarted" ->
              {:cont, [total_estimate + task.estimate, %{tasks | Now: tasks[:Now] ++ [task]}]}

            true ->
              {:cont, [total_estimate + task.estimate, %{tasks | Next: tasks[:Next] ++ [task]}]}
          end
        end
      )

    tasks
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

    query =
      from t in Task,
        where:
          t.stage == ^above_task.stage and
            t.task_order >= ^new_order

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

    Repo.update_all(query, inc: [task_order: 1])
    update_task(task, %{"task_order" => new_order, "stage" => above_task.stage})
  end

  def move_task_below(%Task{} = task, %Task{} = below_task) do
    new_order = below_task.task_order + 1

    query =
      from t in Task,
        where:
          t.stage == ^below_task.stage and
            t.task_order >= ^new_order

    query =
      if not is_nil(below_task.team_id) do
        where(query, [t], t.team_id == ^below_task.team_id)
      else
        where(query, [t], t.creator_id == ^below_task.creator_id)
      end

    Repo.update_all(query, inc: [task_order: 1])

    update_task(task, %{"task_order" => new_order, "stage" => below_task.stage})
  end

  def get_max_task_order_for(%User{} = creator, stage) do
    query =
      from t in Task,
        where: t.creator_id == ^creator.id and t.stage == ^stage,
        select: max(t.task_order)

    Repo.one(query)
  end

  def get_max_task_order_for(%Team{} = team, stage) do
    query =
      from t in Task,
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

  def start_task(%Task{} = task) do
    update_task(task, %{"status" => "Started", "stage" => "Now"})
  end

  def finish_task(%Task{} = task) do
    update_task(task, %{"status" => "Finished"})
  end

  def deliver_task(%Task{} = task) do
    update_task(task, %{"status" => "Delivered"})
  end

  def accept_task(%Task{} = task) do
    update_task(task, %{"status" => "Accepted"})
  end

  def reject_task(%Task{} = task) do
    update_task(task, %{"status" => "Rejected"})
  end

  def close_task(%Task{} = task) do
    update_task(task, %{"status" => "Closed"})
  end

  # Be able to delete a Task
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  def delete_tasks_with_slugs(user, slugs) do
    query =
      from t in Task,
        where: t.creator_id == ^user.id and t.slug in ^slugs

    Repo.delete_all(query)
  end
end
