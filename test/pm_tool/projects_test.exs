defmodule PmTool.ProjectsTest do
  use PmTool.DataCase

  alias PmTool.Projects

  describe "projects" do
    alias PmTool.Projects.Project

    import PmTool.ProjectsFixtures

    @invalid_attrs %{name: nil, description: nil}

    test "list_projects/0 returns all projects" do
      project = project_fixture()
      assert Projects.list_projects() == [project]
    end

    test "get_project!/1 returns the project with given id" do
      project = project_fixture()
      assert Projects.get_project!(project.id) == project
    end

    test "create_project/1 with valid data creates a project" do
      valid_attrs = %{name: "some name", description: "some description"}

      assert {:ok, %Project{} = project} = Projects.create_project(valid_attrs)
      assert project.name == "some name"
      assert project.description == "some description"
    end

    test "create_project/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_project(@invalid_attrs)
    end

    test "update_project/2 with valid data updates the project" do
      project = project_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description"}

      assert {:ok, %Project{} = project} = Projects.update_project(project, update_attrs)
      assert project.name == "some updated name"
      assert project.description == "some updated description"
    end

    test "update_project/2 with invalid data returns error changeset" do
      project = project_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_project(project, @invalid_attrs)
      assert project == Projects.get_project!(project.id)
    end

    test "delete_project/1 deletes the project" do
      project = project_fixture()
      assert {:ok, %Project{}} = Projects.delete_project(project)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_project!(project.id) end
    end

    test "change_project/1 returns a project changeset" do
      project = project_fixture()
      assert %Ecto.Changeset{} = Projects.change_project(project)
    end
  end

  describe "members" do
    alias PmTool.Projects.Member

    import PmTool.ProjectsFixtures

    @invalid_attrs %{user_id: nil, project_id: nil}

    test "list_members/0 returns all members" do
      member = member_fixture()
      assert Projects.list_members() == [member]
    end

    test "get_member!/1 returns the member with given id" do
      member = member_fixture()
      assert Projects.get_member!(member.id) == member
    end

    test "create_member/1 with valid data creates a member" do
      valid_attrs = %{user_id: 42, project_id: 42}

      assert {:ok, %Member{} = member} = Projects.create_member(valid_attrs)
      assert member.user_id == 42
      assert member.project_id == 42
    end

    test "create_member/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Projects.create_member(@invalid_attrs)
    end

    test "update_member/2 with valid data updates the member" do
      member = member_fixture()
      update_attrs = %{user_id: 43, project_id: 43}

      assert {:ok, %Member{} = member} = Projects.update_member(member, update_attrs)
      assert member.user_id == 43
      assert member.project_id == 43
    end

    test "update_member/2 with invalid data returns error changeset" do
      member = member_fixture()
      assert {:error, %Ecto.Changeset{}} = Projects.update_member(member, @invalid_attrs)
      assert member == Projects.get_member!(member.id)
    end

    test "delete_member/1 deletes the member" do
      member = member_fixture()
      assert {:ok, %Member{}} = Projects.delete_member(member)
      assert_raise Ecto.NoResultsError, fn -> Projects.get_member!(member.id) end
    end

    test "change_member/1 returns a member changeset" do
      member = member_fixture()
      assert %Ecto.Changeset{} = Projects.change_member(member)
    end
  end
end
