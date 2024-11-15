defmodule PmTool.TasksFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PmTool.Tasks` context.
  """

  @doc """
  Generate a task.
  """
  def task_fixture(attrs \\ %{}) do
    {:ok, task} =
      attrs
      |> Enum.into(%{
        creator_id: 42,
        description: "some description",
        name: "some name",
        owner_id: 42,
        project_id: 42
      })
      |> PmTool.Tasks.create_task()

    task
  end
end
