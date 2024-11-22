defmodule PmTool.Tasks.Blocker do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blockers" do
    field :description, :string
    field :done, :boolean, default: false
    belongs_to :task, PmTool.Tasks.Task
    timestamps()
  end

  @doc false
  def changeset(blocker, attrs) do
    blocker
    |> cast(attrs, [:description, :task_id, :done])
    |> validate_required([:description, :task_id, :done])
  end
end
