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

  def list_tasks(%User{} = user) do
    velocity = determine_velocity(user)

    Repo.all(base_list_tasks_query(user))
    |> separate_tasks_into_stages(velocity)
  end

  def list_tasks(%Team{} = team) do
    velocity = determine_velocity(team)

    Repo.all(base_list_tasks_query(team))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(velocity)
  end

  def list_tasks_for_tag(%User{} = user, tag) do
    query =
      from t in base_list_tasks_query(user),
        where: ^tag in t.tags

    velocity = determine_velocity(user)

    Repo.all(query)
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(velocity)
  end

  def list_tasks(%Team{} = team, project_slug) do
    velocity = determine_velocity(team)
    project = Projects.get_project_by_slug!(project_slug)

    query =
      from t in base_list_tasks_query(team),
        where: ^project.tag in t.project_tags

    Repo.all(query)
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(velocity)
  end

  def list_tasks(%User{} = user, teams) do
    team_ids = Enum.map(teams, & &1.id)
    query =
      from t in base_list_tasks_query(),
        where: t.creator_id == ^user.id or t.team_id in ^team_ids,
        order_by: [t.stage, t.task_order]

    velocity = determine_velocity(user)
    team_velocities = for team <- teams, into: %{}, do: {team.id, determine_velocity(team)}

    Repo.all(query)
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(velocity, team_velocities)
  end

  def list_tasks(%User{} = user, project_slug, teams) do
    team_ids = Enum.map(teams, & &1.id)
    project = Projects.get_project_by_slug!(project_slug)

    query =
      from t in base_list_tasks_query(),
        where:
          (t.creator_id == ^user.id or t.team_id in ^team_ids) and
          ^project.tag in t.project_tags,
        order_by: [t.stage, t.task_order]

    velocity = determine_velocity(user)
    team_velocities = for team <- teams, into: %{}, do: {team.id, determine_velocity(team)}

    Repo.all(query)
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(velocity, team_velocities)
  end

  def base_list_tasks_query() do
    from t in Task,
      order_by: [
        desc: t.status == "Accepted",
        desc: t.status == "Closed",
        desc: t.status == "Delivered",
        desc: t.status == "Finished",
        desc: t.status == "Started",
        desc: t.status == "Rejected",
        desc: t.status == "Unstarted",
        desc: t.status == "Unappraised",
        asc: t.task_order
      ]
  end

  def base_list_tasks_query(%Team{} = team) do
    from t in Task,
      where: t.team_id == ^team.id,
      order_by: [
        desc: t.status == "Accepted",
        desc: t.status == "Closed",
        desc: t.status == "Delivered",
        desc: t.status == "Finished",
        desc: t.status == "Started",
        desc: t.status == "Rejected",
        desc: t.status == "Unstarted",
        desc: t.status == "Unappraised",
        asc: t.task_order
      ]
  end

  def base_list_tasks_query(%User{} = user) do
    from t in Task,
      where: t.creator_id == ^user.id and is_nil(t.team_id),
      order_by: [
        desc: t.status == "Accepted",
        desc: t.status == "Closed",
        desc: t.status == "Delivered",
        desc: t.status == "Finished",
        desc: t.status == "Started",
        desc: t.status == "Rejected",
        desc: t.status == "Unstarted",
        desc: t.status == "Unappraised",
        asc: t.task_order
      ]
  end

  def determine_velocity(%Team{} = team) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)
    last_period_end_date = Date.utc_today() |> Date.end_of_week() |> Date.add(-7)
    two_period_end_date = Date.add(last_period_end_date, -7)

    two_iterations =
      two_period_end_date |> DateTime.new!(just_before_midnight, "Etc/UTC")

    query =
      from t in Task,
        where:
          t.team_id == ^team.id and
            t.status == "Accepted" and
            t.status_updated_at >= ^two_iterations,
        select: sum(t.estimate)

    velocity = Repo.one(query) || 0
    velocity = round(velocity)
    if velocity <= 20, do: 20, else: velocity
  end

  def determine_velocity(%User{} = user) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)
    last_period_end_date = Date.utc_today() |> Date.end_of_week() |> Date.add(-7)
    two_period_end_date = Date.add(last_period_end_date, -7)

    two_iterations =
      two_period_end_date |> DateTime.new!(just_before_midnight, "Etc/UTC")

    query =
      from t in Task,
        where:
          t.creator_id == ^user.id and
            is_nil(t.team_id) and
            t.status == "Accepted" and
            t.status_updated_at >= ^two_iterations,
        select: sum(t.estimate)

    velocity = Repo.one(query) || 0
    velocity = round(velocity)
    if velocity <= 20, do: 20, else: velocity
  end

  def get_iteration_end_times() do
    # Limit the results until the estimate adds up to 30
    last_period_end_date = Date.utc_today() |> Date.end_of_week() |> Date.add(-7)
    two_period_end_date = Date.add(last_period_end_date, -7)
    three_period_end_date = Date.add(last_period_end_date, -14)
    earlier_end_date = Date.add(last_period_end_date, -21)

    just_before_midnight = Time.new!(23, 59, 59, 999_999)
    last_period_end = DateTime.new!(last_period_end_date, just_before_midnight, "Etc/UTC")
    two_period_end = DateTime.new!(two_period_end_date, just_before_midnight, "Etc/UTC")
    three_period_end = DateTime.new!(three_period_end_date, just_before_midnight, "Etc/UTC")
    earlier_end = DateTime.new!(earlier_end_date, just_before_midnight, "Etc/UTC")

    {last_period_end, two_period_end, three_period_end, earlier_end} 
  end

  def sort_task(task, [total_estimate, current_period, tasks], iteration_end_times, velocity) do
    {last_period_end, two_period_end, three_period_end, earlier_end} = iteration_end_times
    status_updated_at = DateTime.from_naive!(task.status_updated_at, "Etc/UTC")
    cond do
      # If it was Accepted more than 7 days ago, then it is marked as Done
      Enum.member?(["Accepted", "Closed"], task.status) and
          DateTime.compare(status_updated_at, last_period_end) == :lt ->
        cond do
          DateTime.compare(status_updated_at, earlier_end) == :lt ->
             [
               total_estimate,
               current_period,
               Map.put(
                 tasks,
                 :Done,
                 Map.put(tasks[:Done], :earlier, tasks[:Done][:earlier] ++ [task])
               )
             ]

          DateTime.compare(status_updated_at, three_period_end) == :lt ->
             [
               total_estimate,
               current_period,
               Map.put(
                 tasks,
                 :Done,
                 Map.put(tasks[:Done], :three, tasks[:Done][:three] ++ [task])
               )
             ]

          DateTime.compare(status_updated_at, two_period_end) == :lt ->
             [
               total_estimate,
               current_period,
               Map.put(
                 tasks,
                 :Done,
                 Map.put(tasks[:Done], :two, tasks[:Done][:two] ++ [task])
               )
             ]

          true ->
             [
               total_estimate,
               current_period,
               Map.put(
                 tasks,
                 :Done,
                 Map.put(tasks[:Done], :last, tasks[:Done][:last] ++ [task])
               )
             ]
        end

      task.stage == "Later" ->
         [total_estimate, current_period, Map.put(tasks, :Later, tasks[:Later] ++ [task])]

      total_estimate + task.estimate <= velocity or
          (task.status != "Unstarted" and task.status != "Unappraised") ->
         [
           total_estimate + task.estimate,
           current_period,
           %{tasks | Now: tasks[:Now] ++ [task]}
         ]

      true ->
        current_period =
          case total_estimate + task.estimate > velocity * (current_period + 1) do
            true ->
              current_period + 1

            false ->
              current_period
          end

        tasks =
          case tasks[:Next][current_period] do
            nil ->
              Map.put(tasks, :Next, Map.put(tasks[:Next], current_period, [task]))

            current_period_tasks ->
              Map.put(
                tasks,
                :Next,
                Map.put(tasks[:Next], current_period, current_period_tasks ++ [task])
              )
          end

        [total_estimate + task.estimate, current_period, tasks]
    end
  end

  def separate_tasks_into_stages(unsorted_tasks, user_velocity, team_velocities) do
    iteration_end_times = get_iteration_end_times()
    team_estimates = for {team_id, _velocity} <- team_velocities, into: %{}, do: {team_id, 0}
    team_periods = team_estimates
    [_now_estimate, _current_period, _team_estimates, _team_periods, tasks] =
      Enum.reduce_while(
        unsorted_tasks,
        [
          0,
          0,
          team_estimates,
          team_periods,
          %{Now: [], Next: %{}, Done: %{last: [], two: [], three: [], earlier: []}, Later: []}
        ],
        fn task, acc ->
          [user_estimate, current_period, team_estimates, team_periods, tasks] = acc
          if is_nil(task.team_id) do
            [user_estimate, current_period, tasks] = sort_task(task, [user_estimate, current_period, tasks], iteration_end_times, user_velocity)
            {:cont, [user_estimate, current_period, team_estimates, team_periods, tasks]}
          else
            [team_estimate, current_period, tasks] = sort_task(task, [team_estimates[task.team_id], team_periods[task.team_id], tasks], iteration_end_times, team_velocities[task.team_id])
            {:cont, [user_estimate, current_period, Map.put(team_estimates, task.team_id, team_estimate), Map.put(team_periods, task.team_id, current_period), tasks]}
          end
        end
      )

    tasks
  end
 
  def separate_tasks_into_stages(unsorted_tasks, velocity) do
    iteration_end_times = get_iteration_end_times()
    [_now_estimate, _current_period, tasks] =
      Enum.reduce_while(
        unsorted_tasks,
        [
          0,
          0,
          %{Now: [], Next: %{}, Done: %{last: [], two: [], three: [], earlier: []}, Later: []}
        ],
        fn task, acc ->
          {:cont, sort_task(task, acc, iteration_end_times, velocity)}
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

  def replace_project_tag(old_project_tag, new_project_tag) do
    query = from t in Task, where: ^old_project_tag in t.project_tags
    tasks = Repo.all(query)

    Enum.each(
      tasks,
      fn task ->
        update_task(task, %{
          "project_tags" => (task.project_tags -- [old_project_tag]) ++ [new_project_tag]
        })
      end
    )
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

  def estimate_task(%Task{} = task, estimate) do
    update_task(task, %{"estimate" => estimate, "status" => "Unstarted"})
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
