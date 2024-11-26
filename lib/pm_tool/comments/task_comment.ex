defmodule PmTool.Comments.TaskComment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "task_comments" do
    belongs_to :user, PmTool.Accounts.User
    belongs_to :task, PmTool.Tasks.Task
    field :info, :string

    timestamps()
  end

  @doc false
  def changeset(task_comment, attrs) do
    task_comment
    |> cast(attrs, [:user_id, :task_id, :info])
    |> validate_required([:user_id, :task_id, :info])
  end
end
