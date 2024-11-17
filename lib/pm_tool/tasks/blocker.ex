defmodule PmTool.Tasks.Blocker do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blockers" do
    belongs_to :task, PmTool.Tasks.Task
    field :description, :string
    field :done, :boolean, default: false
    
    timestamps()
  end

  @doc false
  def changeset(blocker, attrs) do
    blocker
    |> cast(attrs, [:task_id, :description, :done])
    |> validate_required([:task_id, :description])
  end
end
