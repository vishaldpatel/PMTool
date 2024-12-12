defmodule PmTool.Projects.ProjectTask do
  use Ecto.Schema
  import Ecto.Changeset

  schema "project_tasks" do
    belongs_to :project, PmTool.Projects.Project
    belongs_to :task, PmTool.Tasks.Task
  end

  @doc false
  def changeset(project_task, attrs) do
    project_task
    |> cast(attrs, [:task_id, :project_id])
    |> validate_required([:task_id, :project_id])
    |> unique_constraint([:project_id, :task_id], name: :project_tasks_project_id_task_id_index)
  end
end
