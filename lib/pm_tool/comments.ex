defmodule PmTool.Comments do
  @moduledoc """
  The Comments context.
  """

  import Ecto.Query, warn: false
  alias PmTool.Repo

  alias PmTool.Comments.TaskComment

  # Be able to create a TaskComment
  def create_task_comment(attrs \\ %{}) do
    %TaskComment{}
    |> TaskComment.changeset(attrs)
    |> Repo.insert()
  end

  def update_task_comment(%TaskComment{} = task_comment, attrs) do
    task_comment
    |> TaskComment.changeset(attrs)
    |> Repo.update()
  end

  # Get comments for task order by created_at
  def get_comments_for_task(task) do
    query = from c in TaskComment,
      where: c.task_id == ^task.id,
      order_by: [desc: c.inserted_at]
    Repo.all(query)
  end

  # Be able to delete a TaskComment
  def delete_task_comment(%TaskComment{} = task_comment) do
    Repo.delete(task_comment)
  end
end
