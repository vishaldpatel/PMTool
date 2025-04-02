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
  alias PmTool.Teams.TeamMember
  alias PmTool.Teams.Change

  def zero_tasks() do
    %{
      Now: %{done: [], ongoing: [], unstarted: []},
      Next: %{},
      Done: %{current: [], last: [], two: [], three: [], earlier: []},
      Later: []
    }
  end

  def get_velocity(user_or_team) do
    case user_or_team do
      %User{} = user ->
        determine_velocity(user)

      %Team{} = team ->
        determine_velocity(team)

      _ ->
        20
    end
  end

  def get_velocities(teams) do
    for team <- teams, into: %{}, do: {team.id, determine_velocity(team)}
  end

  def last_period_end_date() do
    Date.utc_today()
    |> Date.end_of_week()
    |> Date.add(-7)
  end

  def now_and_next_stage_query(query) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)

    last_period_end_date =
      last_period_end_date() |> DateTime.new!(just_before_midnight, "Etc/UTC")

    from t in query,
      where:
        (t.is_milestone == true and not is_nil(t.due_date) and t.due_date > ^last_period_end_date) or
          (t.is_milestone != true and
             (((t.status == "Accepted" or t.status == "Closed") and
                 t.status_updated_at > ^last_period_end_date) or
                (t.stage == "Now" and t.status != "Accepted" and t.status != "Closed")))
  end

  def later_stage_query(query) do
    from t in query,
      where: t.stage == "Later" and (t.status == "Unstarted" or t.status == "Unappraised"),
      order_by: [asc: t.task_order]
  end

  def done_stage_query(query, :all_done_tasks) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)

    last_period_end_date =
      last_period_end_date() |> DateTime.new!(just_before_midnight, "Etc/UTC")

    from t in query,
      where:
        ((t.status == "Accepted" or t.status == "Closed") and
           t.status_updated_at <= ^last_period_end_date) or
          (t.is_milestone == true and not is_nil(t.due_date) and
             t.due_date <= ^last_period_end_date),
      order_by:
        fragment(
          "CASE WHEN is_milestone = true AND due_date IS NOT NULL THEN due_date ELSE status_updated_at END DESC"
        )
  end

  def done_stage_query(query) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)

    last_period_end_date =
      last_period_end_date() |> DateTime.new!(just_before_midnight, "Etc/UTC")

    max_end_date =
      last_period_end_date() |> Date.add(-21) |> DateTime.new!(just_before_midnight, "Etc/UTC")

    from t in query,
      where:
        ((t.status == "Accepted" or t.status == "Closed") and
           t.status_updated_at <= ^last_period_end_date and
           t.status_updated_at > ^max_end_date) or
          (t.is_milestone == true and not is_nil(t.due_date) and
             t.due_date <= ^last_period_end_date and
             t.due_date > ^max_end_date),
      order_by:
        fragment(
          "CASE WHEN is_milestone = true AND due_date IS NOT NULL THEN due_date ELSE status_updated_at END DESC"
        )
  end

  def get_now_and_next_tasks_for_team(query, team_velocity) do
    Repo.all(now_and_next_stage_query(query))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(team_velocity, :Now)
  end

  def get_later_tasks_for_team(query, team_velocity) do
    Repo.all(later_stage_query(query))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(team_velocity, :Later)
  end

  def get_all_done_tasks_for_team(query, team_velocity) do
    Repo.all(done_stage_query(query, :all_done_tasks))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(team_velocity, :Done)
  end

  def get_done_tasks_for_team(query, team_velocity) do
    Repo.all(done_stage_query(query))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_tasks_into_stages(team_velocity, :Done)
  end

  defp get_results_for_team(query, team_velocity) do
    get_now_and_next_tasks_for_team(query, team_velocity)
    |> Map.merge(get_later_tasks_for_team(query, team_velocity))
    |> Map.merge(get_done_tasks_for_team(query, team_velocity))
  end

  defp get_results_for_team(query, team_velocity, :all_done_tasks) do
    get_now_and_next_tasks_for_team(query, team_velocity)
    |> Map.merge(get_later_tasks_for_team(query, team_velocity))
    |> Map.merge(get_all_done_tasks_for_team(query, team_velocity))
  end

  defp get_now_and_next_tasks_for_user_and_teams(query, user_velocity, team_velocities) do
    Repo.all(now_and_next_stage_query(query))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_team_tasks_into_stages(user_velocity, team_velocities, :Now)
  end

  defp get_later_tasks_for_user_and_teams(query, user_velocity, team_velocities) do
    Repo.all(later_stage_query(query))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_team_tasks_into_stages(user_velocity, team_velocities, :Later)
  end

  defp get_all_done_tasks_for_user_and_teams(query, user_velocity, team_velocities) do
    Repo.all(done_stage_query(query, :all_done_tasks))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_team_tasks_into_stages(user_velocity, team_velocities, :Done)
  end

  defp get_done_tasks_for_user_and_teams(query, user_velocity, team_velocities) do
    Repo.all(done_stage_query(query))
    |> Repo.preload(team: [:team_members])
    |> Repo.preload(:owner)
    |> separate_team_tasks_into_stages(user_velocity, team_velocities, :Done)
  end

  defp get_results_for_user_and_teams(query, user_velocity, team_velocities, :all_done_tasks) do
    get_now_and_next_tasks_for_user_and_teams(query, user_velocity, team_velocities)
    |> Map.merge(get_later_tasks_for_user_and_teams(query, user_velocity, team_velocities))
    |> Map.merge(get_all_done_tasks_for_user_and_teams(query, user_velocity, team_velocities))
  end

  defp get_results_for_user_and_teams(query, user_velocity, team_velocities) do
    get_now_and_next_tasks_for_user_and_teams(query, user_velocity, team_velocities)
    |> Map.merge(get_later_tasks_for_user_and_teams(query, user_velocity, team_velocities))
    |> Map.merge(get_done_tasks_for_user_and_teams(query, user_velocity, team_velocities))
  end

  def list_done_tasks(%Team{} = team, team_velocity, done_months_ago) do
    case done_months_ago do
      nil ->
        base_list_tasks_query(team)
        |> get_done_tasks_for_team(team_velocity)

      _ ->
        query =
          from t in base_list_tasks_query(team),
            where:
              t.status == "Accepted" or t.status == "Closed" or
                (t.is_milestone == true and not is_nil(t.due_date)),
            order_by:
              fragment(
                "CASE WHEN is_milestone = true AND due_date IS NOT NULL THEN due_date ELSE status_updated_at END DESC"
              ),
            limit: ^20,
            offset: ^((done_months_ago * -1 - 1) * 20)

        done_tasks =
          Repo.all(query)
          |> Repo.preload(team: [:team_members])
          |> Repo.preload(:owner)

        %{
          Now: %{done: [], ongoing: [], unstarted: []},
          Next: %{},
          Done: %{current: [], last: [], two: [], three: [], earlier: done_tasks},
          Later: []
        }
    end
  end

  def list_done_tasks(%User{} = user, teams, user_velocity, team_velocities, done_months_ago) do
    team_ids = get_ids_from(teams)

    case done_months_ago do
      nil ->
        query =
          from t in base_list_tasks_query(),
            where: t.creator_id == ^user.id or t.team_id in ^team_ids

        get_done_tasks_for_user_and_teams(query, user_velocity, team_velocities)

      _ ->
        just_before_midnight = Time.new!(23, 59, 59, 999_999)

        max_end_date =
          last_period_end_date()
          |> Date.add(-21)
          |> DateTime.new!(just_before_midnight, "Etc/UTC")

        query =
          from t in base_list_tasks_query(),
            where:
              (t.creator_id == ^user.id or t.team_id in ^team_ids) and
                (((t.status == "Accepted" or t.status == "Closed") and
                    t.status_updated_at <= ^max_end_date) or
                   (t.is_milestone == true and not is_nil(t.due_date) and
                      t.due_date <= ^max_end_date)),
            order_by:
              fragment(
                "CASE WHEN is_milestone = true AND due_date IS NOT NULL THEN due_date ELSE status_updated_at END DESC"
              ),
            limit: ^20,
            offset: ^((done_months_ago * -1 - 1) * 20)

        done_tasks =
          Repo.all(query)
          |> Repo.preload(team: [:team_members])
          |> Repo.preload(:owner)

        %{
          Now: %{done: [], ongoing: [], unstarted: []},
          Next: %{},
          Done: %{current: [], last: [], two: [], three: [], earlier: done_tasks},
          Later: []
        }
    end
  end

  def list_tasks(%Team{} = team, team_velocity) do
    base_list_tasks_query(team)
    |> get_results_for_team(team_velocity)
  end

  def list_tasks_for_tag(%User{} = user, teams, tag, user_velocity, team_velocities) do
    team_ids = get_ids_from(teams)

    query =
      from t in base_list_tasks_query(),
        where:
          (t.creator_id == ^user.id or t.team_id in ^team_ids) and
            ^tag in t.tags,
        order_by: [t.stage, t.task_order]

    get_results_for_user_and_teams(query, user_velocity, team_velocities)
  end

  def list_tasks(%Team{} = team, project_slug, team_velocity) do
    project = Projects.get_project_by_slug!(project_slug)

    query =
      from t in base_list_tasks_query(team),
        where: ^project.tag in t.project_tags

    get_results_for_team(query, team_velocity, :all_done_tasks)
  end

  def list_tasks(%User{} = user, project_slug, teams, user_velocity, team_velocities) do
    team_ids = get_ids_from(teams)
    project = Projects.get_project_by_slug!(project_slug)

    query =
      from t in base_list_tasks_query(),
        where:
          (t.creator_id == ^user.id or t.team_id in ^team_ids) and
            ^project.tag in t.project_tags,
        order_by: [t.stage, t.task_order]

    get_results_for_user_and_teams(query, user_velocity, team_velocities, :all_done_tasks)
  end

  def list_tasks(%User{} = user, teams, user_velocity, team_velocities) do
    team_ids = get_ids_from(teams)

    query =
      from t in base_list_tasks_query(),
        where: t.creator_id == ^user.id or t.team_id in ^team_ids,
        order_by: [t.stage, t.task_order]

    get_results_for_user_and_teams(query, user_velocity, team_velocities)
  end

  defp get_ids_from(objects) do
    Enum.map(objects, & &1.id)
  end

  def base_list_tasks_query() do
    from(t in Task)
  end

  def base_list_tasks_query(%Team{} = team) do
    from t in Task,
      where: t.team_id == ^team.id
  end

  def base_list_tasks_query(%TeamMember{} = team_member) do
    from t in Task,
      where: t.owner_id == ^team_member.id,
      select: t
  end

  def base_list_private_tasks_query(%User{} = user) do
    from t in Task,
      where: t.creator_id == ^user.id and is_nil(t.team_id)
  end

  defp determine_velocity(%Team{} = team) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)
    last_period_end_date = last_period_end_date()
    two_period_end_date = Date.add(last_period_end_date, -7)

    two_iterations =
      two_period_end_date |> DateTime.new!(just_before_midnight, "Etc/UTC")

    query =
      from t in Task,
        where:
          t.team_id == ^team.id and
            t.is_milestone != true and
            t.status == "Accepted" and
            t.status_updated_at >= ^two_iterations,
        select: sum(t.estimate)

    velocity = Repo.one(query) || 0
    velocity = round(velocity)
    if velocity <= 20, do: 20, else: velocity
  end

  defp determine_velocity(%User{} = user) do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)
    last_period_end_date = last_period_end_date()
    two_period_end_date = Date.add(last_period_end_date, -7)

    two_iterations =
      two_period_end_date |> DateTime.new!(just_before_midnight, "Etc/UTC")

    query =
      from t in Task,
        where:
          t.creator_id == ^user.id and
            is_nil(t.team_id) and
            t.is_milestone != true and
            t.status == "Accepted" and
            t.status_updated_at >= ^two_iterations,
        select: sum(t.estimate)

    velocity = Repo.one(query) || 0
    velocity = round(velocity)
    if velocity <= 20, do: 20, else: velocity
  end

  def get_iteration_end_times() do
    just_before_midnight = Time.new!(23, 59, 59, 999_999)

    Enum.map(0..4, fn slot ->
      Date.utc_today()
      |> Date.end_of_week()
      |> Date.add(-7 * slot)
      |> DateTime.new!(just_before_midnight)
    end)
  end

  defp sort_task(
         task,
         [total_estimate, current_period, tasks],
         iteration_end_times,
         velocity,
         stage
       ) do
    last_period_end = Enum.at(iteration_end_times, 1)
    slots = [{4, :earlier}, {3, :three}, {2, :two}, {1, :last}, {0, :current}]

    task =
      case task.is_milestone == true do
        true ->
          Map.put(task, :estimate, 0)

        false ->
          task
      end

    new_total_estimate = total_estimate + task.estimate

    case stage do
      :Done ->
        Enum.find_value(slots, fn {slot, period_name} ->
          iteration_end_time = Enum.fetch!(iteration_end_times, slot)

          if (((is_nil(task.due_date) and task.is_milestone == true) or task.is_milestone != true) and
                Date.diff(task.status_updated_at, iteration_end_time) <= 0) or
               (task.is_milestone == true and not is_nil(task.due_date) and
                  Date.diff(task.due_date, iteration_end_time) <= 0) do
            [
              total_estimate,
              current_period,
              Map.put(
                tasks,
                :Done,
                Map.put(tasks[:Done], period_name, tasks[:Done][period_name] ++ [task])
              )
            ]
          end
        end)

      :Later ->
        [total_estimate, current_period, Map.put(tasks, :Later, tasks[:Later] ++ [task])]

      :Now ->
        cond do
          # Manage milestones separately because they need
          # more flexibility to move about.
          task.is_milestone == true ->
            current_period = div(new_total_estimate, velocity)

            [
              total_estimate,
              current_period,
              cond do
                task.status == "Accepted" ->
                  Map.put(
                    tasks,
                    :Now,
                    Map.put(tasks[:Now], :ongoing, tasks[:Now][:ongoing] ++ [task])
                  )

                not is_nil(task.due_date) ->
                  due_date_diff = Date.diff(task.due_date, Date.utc_today())
                  due_period = div(Date.diff(task.due_date, last_period_end), 7)
                  due_period_tasks = tasks[:Next][due_period]

                  cond do
                    due_date_diff < 0 ->
                      Map.put(
                        tasks,
                        :Now,
                        Map.put(tasks[:Now], :done, tasks[:Now][:done] ++ [task])
                      )

                    due_date_diff == 0 ->
                      Map.put(
                        tasks,
                        :Now,
                        Map.put(tasks[:Now], :ongoing, tasks[:Now][:ongoing] ++ [task])
                      )

                    due_period == 0 ->
                      Map.put(
                        tasks,
                        :Now,
                        Map.put(tasks[:Now], :unstarted, tasks[:Now][:unstarted] ++ [task])
                      )

                    is_nil(due_period_tasks) ->
                      Map.put(tasks, :Next, Map.put(tasks[:Next], due_period, [task]))

                    true ->
                      Map.put(
                        tasks,
                        :Next,
                        Map.put(tasks[:Next], due_period, due_period_tasks ++ [task])
                      )
                  end

                current_period == 0 ->
                  Map.put(
                    tasks,
                    :Now,
                    Map.put(tasks[:Now], :unstarted, tasks[:Now][:unstarted] ++ [task])
                  )

                is_nil(tasks[:Next][current_period]) ->
                  Map.put(tasks, :Next, Map.put(tasks[:Next], current_period, [task]))

                true ->
                  Map.put(
                    tasks,
                    :Next,
                    Map.put(tasks[:Next], current_period, tasks[:Next][current_period] ++ [task])
                  )
              end
            ]

          new_total_estimate <= velocity or
              (task.status != "Unstarted" and task.status != "Unappraised") ->
            [
              new_total_estimate,
              current_period,
              cond do
                Enum.member?(["Accepted", "Closed"], task.status) ->
                  Map.put(
                    tasks,
                    :Now,
                    Map.put(tasks[:Now], :done, tasks[:Now][:done] ++ [task])
                  )

                Enum.member?(["Started", "Rejected", "Finished"], task.status) ->
                  Map.put(
                    tasks,
                    :Now,
                    Map.put(tasks[:Now], :ongoing, tasks[:Now][:ongoing] ++ [task])
                  )

                true ->
                  Map.put(
                    tasks,
                    :Now,
                    Map.put(tasks[:Now], :unstarted, tasks[:Now][:unstarted] ++ [task])
                  )
              end
            ]

          true ->
            current_period = div(new_total_estimate, velocity)

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

            [new_total_estimate, current_period, tasks]
        end
    end
  end

  defp sort_and_merge_now_and_done_tasks(tasks, stage) do
    case stage do
      :Now ->
        now_tasks = tasks[:Now]
        next_tasks = tasks[:Next]

        now_status_order = %{
          "Accepted" => "1",
          "Closed" => "1",
          "Finished" => "2",
          "Started" => "3",
          "Rejected" => "4",
          "Unstarted" => "5",
          "Unappraised" => "6"
        }

        now_tasks =
          now_tasks
          |> Map.put(
            :done,
            Enum.sort_by(
              now_tasks[:done],
              &"#{now_status_order[&1.status]}-#{&1.status_updated_at}"
            )
          )
          |> Map.put(
            :ongoing,
            Enum.sort_by(
              now_tasks[:ongoing],
              &"#{now_status_order[&1.status]}-#{&1.status_updated_at}"
            )
          )
          |> Map.put(:unstarted, Enum.sort_by(now_tasks[:unstarted], & &1.task_order))

        %{}
        |> Map.put(:Now, (now_tasks[:done] ++ now_tasks[:ongoing]) ++ now_tasks[:unstarted])
        |> Map.put(:Next, next_tasks)

      :Later ->
        %{Later: tasks[:Later]}

      :Done ->
        done_tasks = tasks[:Done]

        done_tasks =
          done_tasks
          |> Map.put(:last, Enum.sort_by(done_tasks[:last], & &1.status_updated_at, :desc))
          |> Map.put(:two, Enum.sort_by(done_tasks[:two], & &1.status_updated_at, :desc))
          |> Map.put(:three, Enum.sort_by(done_tasks[:three], & &1.status_updated_at, :desc))
          |> Map.put(:earlier, Enum.sort_by(done_tasks[:earlier], & &1.status_updated_at, :desc))

        %{Done: done_tasks}

      _ ->
        %{}
    end
  end

  defp separate_team_tasks_into_stages(
         unsorted_tasks,
         user_velocity,
         team_velocities,
         stage
       ) do
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
          zero_tasks()
        ],
        fn task, acc ->
          [user_estimate, current_period, team_estimates, team_periods, tasks] = acc

          if is_nil(task.team_id) do
            [user_estimate, current_period, tasks] =
              sort_task(
                task,
                [user_estimate, current_period, tasks],
                iteration_end_times,
                user_velocity,
                stage
              )

            {:cont, [user_estimate, current_period, team_estimates, team_periods, tasks]}
          else
            [team_estimate, current_period, tasks] =
              sort_task(
                task,
                [team_estimates[task.team_id], team_periods[task.team_id], tasks],
                iteration_end_times,
                team_velocities[task.team_id],
                stage
              )

            {:cont,
             [
               user_estimate,
               current_period,
               Map.put(team_estimates, task.team_id, team_estimate),
               Map.put(team_periods, task.team_id, current_period),
               tasks
             ]}
          end
        end
      )

    sort_and_merge_now_and_done_tasks(tasks, stage)
  end

  defp separate_tasks_into_stages(unsorted_tasks, velocity, stage) do
    iteration_end_times = get_iteration_end_times()

    [_now_estimate, _current_period, tasks] =
      Enum.reduce_while(
        unsorted_tasks,
        [
          0,
          0,
          zero_tasks()
        ],
        fn task, acc ->
          {:cont, sort_task(task, acc, iteration_end_times, velocity, stage)}
        end
      )

    sort_and_merge_now_and_done_tasks(tasks, stage)
  end

  def list_tags(%User{} = user, teams) do
    team_ids = get_ids_from(teams)

    Repo.all(
      from t in Task, where: t.creator_id == ^user.id or t.team_id in ^team_ids, select: t.tags
    )
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.sort()
    |> Enum.filter(&(!is_nil(&1)))
  end

  # Be able to create a Task
  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  # Be able to update a Task
  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  # Be able to get a Task
  def get_task!(id), do: Repo.get!(Task, id)

  # Get Task by slug
  def get_task_by_slug!(slug), do: Repo.get_by!(Task, slug: slug)
  def get_tasks_for_slugs!(slugs), do: Repo.all(from t in Task, where: t.slug in ^slugs)

  def move_task_above(%Task{} = task, %Task{} = target_task, %User{} = user) do
    prev_order = task.task_order
    target_order = target_task.task_order

    if prev_order > target_order do
      query =
        from t in Task,
          where:
            t.task_order >= ^target_order and
              t.task_order < ^prev_order

      Repo.update_all(query, inc: [task_order: 1])

      update_task(task, %{
        "task_order" => target_order,
        "stage" => target_task.stage,
        "current_user_id" => user.id
      })
    else
      query =
        from t in Task,
          where:
            t.task_order < ^target_order and
              t.task_order >= ^prev_order

      Repo.update_all(query, inc: [task_order: -1])

      update_task(task, %{
        "task_order" => target_order - 1,
        "stage" => target_task.stage,
        "current_user_id" => user.id
      })
    end
  end

  def move_task_below(%Task{} = task, %Task{} = target_task, %User{} = user) do
    prev_order = task.task_order
    target_order = target_task.task_order

    if prev_order < target_order do
      query =
        from t in Task,
          where:
            t.task_order <= ^target_order and
              t.task_order > ^prev_order

      Repo.update_all(query, inc: [task_order: -1])

      update_task(task, %{
        "task_order" => target_order,
        "stage" => target_task.stage,
        "current_user_id" => user.id
      })
    else
      query =
        from t in Task,
          where:
            t.task_order > ^target_order and
              t.task_order <= ^prev_order

      Repo.update_all(query, inc: [task_order: 1])

      update_task(task, %{
        "task_order" => target_order + 1,
        "stage" => target_task.stage,
        "current_user_id" => user.id
      })
    end
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

  def replace_project_tag(old_project_tag, new_project_tag, %User{} = current_user) do
    query = from t in Task, where: ^old_project_tag in t.project_tags
    tasks = Repo.all(query)

    Enum.each(
      tasks,
      fn task ->
        update_task(task, %{
          "project_tags" => (task.project_tags -- [old_project_tag]) ++ [new_project_tag],
          "current_user_id" => current_user.id
        })
      end
    )
  end

  def start_task(%Task{} = task, %User{} = current_user) do
    update_task(task, %{
      "status" => "Started",
      "stage" => "Now",
      "current_user_id" => current_user.id
    })
  end

  def finish_task(%Task{} = task, %User{} = current_user) do
    update_task(task, %{"status" => "Finished", "current_user_id" => current_user.id})
  end

  def accept_task(%Task{} = task, %User{} = current_user) do
    update_task(task, %{"status" => "Accepted", "current_user_id" => current_user.id})
  end

  def reject_task(%Task{} = task, %User{} = current_user) do
    update_task(task, %{"status" => "Rejected", "current_user_id" => current_user.id})
  end

  def close_task(%Task{} = task, %User{} = current_user) do
    update_task(task, %{"status" => "Closed", "current_user_id" => current_user.id})
  end

  def estimate_task(%Task{} = task, estimate, %User{} = current_user) do
    update_task(task, %{
      "estimate" => estimate,
      "status" => "Unstarted",
      "current_user_id" => current_user.id
    })
  end

  # Be able to delete a Task
  def delete_task(%Task{} = task, %User{} = current_user) do
    task
    |> Task.changeset(%{current_user_id: current_user.id})
    |> Repo.delete()
  end

  def move_tasks_with_slugs_to_stage(user, slugs, stage) do
    team_ids_query = from tm in TeamMember, where: tm.email == ^user.email, select: tm.team_id
    team_ids = Repo.all(team_ids_query)

    query =
      from t in Task,
        where: (t.creator_id == ^user.id or t.team_id in ^team_ids) and t.slug in ^slugs

    multi_pass =
      Ecto.Multi.new()
      |> Ecto.Multi.update_all(:move_tasks, query,
        set: [stage: stage, updated_at: DateTime.truncate(DateTime.utc_now(), :second)]
      )

    multi_pass =
      Enum.reduce(Repo.all(query), multi_pass, fn task, acc ->
        acc
        |> Ecto.Multi.insert(
          "change_#{task.id}",
          %Change{
            action: "update",
            name: task.name,
            description: "#{user.name} moved #{task.name} to #{stage}",
            user_id: user.id,
            team_id: task.team_id,
            task_id: task.id,
            project_tags: task.project_tags
          }
        )
      end)

    Repo.transaction(multi_pass)
  end

  def delete_tasks_with_slugs(user, slugs) do
    team_ids_query = from tm in TeamMember, where: tm.email == ^user.email, select: tm.team_id
    team_ids = Repo.all(team_ids_query)

    query =
      from t in Task,
        where: (t.creator_id == ^user.id or t.team_id in ^team_ids) and t.slug in ^slugs

    deleted_tasks = Repo.all(query)
    multi_pass = Ecto.Multi.new() |> Ecto.Multi.delete_all(:delete_tasks, query)

    multi_pass =
      Enum.reduce(deleted_tasks, multi_pass, fn task, acc ->
        acc
        |> Ecto.Multi.insert(
          "change_#{task.id}",
          %Change{
            action: "deleted",
            name: task.name,
            description: "#{user.name} deleted task #{task.name}",
            user_id: user.id,
            team_id: task.team_id,
            project_tags: task.project_tags
          }
        )
      end)

    Repo.transaction(multi_pass)
  end
end
