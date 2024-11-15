defmodule PmTool.Tasks.TaskStatus do
  use Ecto.Schema
  import Ecto.Changeset


  schema "task_status" do
    belongs_to :task, PmTool.Tasks.Task
    field :status, :string

    timestamps()
  end

  @statuses ["unstarted", "started", "finished", "delivered", "rejected", "accepted"]

  @doc false
  def changeset(task_status, attrs) do
    task_status
    |> cast(attrs, [:task_id, :status])
    |> validate_required([:task_id, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
