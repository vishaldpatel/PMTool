defmodule PmTool.Projects.Member do
  use Ecto.Schema
  import Ecto.Changeset

  schema "members" do
    belongs_to :user, PmTool.Accounts.User
    belongs_to :project, PmTool.Projects.Project

    timestamps()
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [:user_id, :project_id])
    |> unique_constraint([:user_id, :project_id], name: :members_project_id_user_id_index)
  end
end
