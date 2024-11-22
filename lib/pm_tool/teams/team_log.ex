defmodule PmTool.Teams.TeamLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "team_logs" do
    field :action, :string
    field :name, :string

    belongs_to :team, PmTool.Teams.Team
    belongs_to :user, PmTool.Accounts.User
    belongs_to :task, PmTool.Tasks.Task

    timestamps()
  end

  @doc false
  def changeset(team_log, attrs) do
    team_log
    |> cast(attrs, [:action, :name, :team_id, :user_id, :task_id])
    |> validate_required([:action, :name, :team_id, :user_id])
  end
end
