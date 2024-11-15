defmodule PmTool.ProjectsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `PmTool.Projects` context.
  """

  @doc """
  Generate a project.
  """
  def project_fixture(attrs \\ %{}) do
    {:ok, project} =
      attrs
      |> Enum.into(%{
        description: "some description",
        name: "some name"
      })
      |> PmTool.Projects.create_project()

    project
  end

  @doc """
  Generate a member.
  """
  def member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> Enum.into(%{
        project_id: 42,
        user_id: 42
      })
      |> PmTool.Projects.create_member()

    member
  end
end
