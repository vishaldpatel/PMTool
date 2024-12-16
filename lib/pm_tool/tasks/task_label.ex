defmodule PmTool.Projects.TaskLabel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_labels" do
    belongs_to :task, PmTool.Tasks.Task
    belongs_to :label, PmTool.Labels.Label

    timestamps()
  end

  @doc false
  def changeset(task_label, attrs) do
    task_label
    |> cast(attrs, [:task_id, :label_id])
    |> validate_required([:task_id, :label_id])
    |> unique_constraint([:task_id, :label_id], name: :task_labels_task_id_label_id_index)
  end
end
