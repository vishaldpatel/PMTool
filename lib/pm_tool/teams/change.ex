defmodule PmTool.Teams.Change do
  use Ecto.Schema
  import Ecto.Changeset

  schema "changes" do
    field :action, :string
    field :name, :string
    field :description, :string

    belongs_to :team, PmTool.Teams.Team
    belongs_to :user, PmTool.Accounts.User
    belongs_to :task, PmTool.Tasks.Task
    belongs_to :team_member, PmTool.Teams.TeamMember

    timestamps()
  end

  @doc false
  def changeset(change, attrs) do
    change
    |> cast(attrs, [:action, :name, :team_id, :user_id, :task_id, :team_member_id, :description])
    |> validate_required([:action, :name, :user_id, :description])
  end
end
