defmodule PmTool.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo

  alias PmTool.Tasks.Task
  alias PmTool.Tasks.TaskStatus
  alias PmTool.Tasks.Stage
  alias PmTool.Projects.Project
  alias PmTool.Projects.Epic
  alias PmTool.Tasks.Blocker

  ###########
  # Getters #
  ###########

  def list_tasks do
    Repo.all(Task)
  end

  def list_tasks_for_project(%Project{id: project_id}) do
    Repo.all(from t in Task, where: t.project_id == ^project_id)
  end

  def list_statuses_for_task(%Task{} = task) do
    query = from t in TaskStatus, where: t.task_id == ^task.id
    Repo.all(query)
  end

  def list_stages_for_task(%Task{} = task) do
    query = from s in Stage, where: s.task_id == ^task.id
    Repo.all(query)
  end

  def get_task_by_id!(id), do: Repo.get!(Task, id)

  def get_task!(url_hash) do 
    Repo.get_by!(Task, url_hash: url_hash)
  end

  def get_status_for_task!(%Task{} = task) do
    query = from t in TaskStatus, where: t.id == ^task.current_status_id
    Repo.one!(query)
  end

  def get_stage_for_task!(%Task{} = task) do
    query = from s in Stage, where: s.id == ^task.current_stage_id
    Repo.one!(query)
  end

  ###########
  # Setters #
  ###########

  def create_task(attrs \\ %{}) do
    %Task{}
    |> Task.changeset(attrs)
    |> Repo.insert()
  end

  def update_task(%Task{} = task, attrs) do
    task
    |> Task.changeset(attrs)
    |> Repo.update()
  end

  defp make_status_current(%Task{} = task, %TaskStatus{} = task_status) do
    if task.current_status_id != task_status.id do
      update_task(task, %{current_status_id: task_status.id})
    else
      {:ok, task}
    end
  end

  def set_task_status(%Task{} = task, new_status) do
    result = %TaskStatus{}
    |> TaskStatus.changeset(%{task_id: task.id, status: new_status})
    |> Repo.insert()

    case result do
      {:ok, task_status} -> make_status_current(task, task_status)
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp make_stage_current(%Task{} = task, %Stage{} = stage) do
    if task.current_stage_id != stage.id do
      update_task(task, %{current_stage_id: stage.id})
    else
      {:ok, task}
    end
  end

  def set_task_stage(%Task{} = task, new_stage) do
    result = %Stage{}
    |> Stage.changeset(%{task_id: task.id, stage: new_stage})
    |> Repo.insert()

    case result do
      {:ok, stage} -> {:ok, make_stage_current(task, stage)}
      {:error, changeset} -> {:error, changeset}
    end
  end

  def change_task(%Task{} = task, attrs \\ %{}) do
    Task.changeset(task, attrs)
  end

  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  #########
  # Epics #
  #########
  def set_epic_for_task(%Task{} = task, %Epic{} = epic) do
    update_task(task, %{epic_id: epic.id})
  end

  def unset_epic_for_task(%Task{} = task) do
    update_task(task, %{epic_id: nil})
  end

  ############
  # Blockers # 
  ############

  def get_blocked_tasks_for_project(%Project{} = project) do
    # Get all tasks for project that have an entry in the blockers table with done = false
    query = from t in Task, 
            join: b in Blocker, on: b.task_id == t.id, 
            where: b.done == false and t.project_id == ^project.id
    Repo.all(query)
  end

  def add_blocker(attrs \\ %{}) do
    %Blocker{}
    |> Blocker.changeset(attrs)
    |> Repo.insert()
  end

  def update_blocker(%Blocker{} = blocker, attrs) do
    blocker
    |> Blocker.changeset(attrs)
    |> Repo.update()
  end

  def mark_blocker_as_done(%Blocker{} = blocker) do
    update_blocker(blocker, %{done: true})
  end

  def mark_blocker_as_undone(%Blocker{} = blocker) do
    update_blocker(blocker, %{done: false})
  end

  def delete_blocker(%Blocker{} = blocker) do
    Repo.delete(blocker)
  end
end
