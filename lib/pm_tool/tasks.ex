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

  def get_task!(combo_slug) do 
    url_hash = combo_slug
    |> String.split("--")
    |> List.first()

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
end
