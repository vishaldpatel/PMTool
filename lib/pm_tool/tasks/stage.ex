defmodule PmTool.Tasks.Stage do
  use Ecto.Schema
  import PmTool.UrlTools
  import Ecto.Changeset

  schema "stages" do
    belongs_to :task, PmTool.Tasks.Task
    field :stage, :string

    timestamps()
  end

  @stages ["icebox", "backlog", "current_iteration", "blocked", "done"]

  @doc false
  def changeset(stage, attrs) do
    stage
    |> cast(attrs, [:task_id, :stage])
    |> validate_required([:task_id, :stage])
    |> validate_inclusion(:stage, @stages)
  end
end
