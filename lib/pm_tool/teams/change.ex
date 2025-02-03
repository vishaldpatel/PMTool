defmodule PmTool.Teams.Change do
  use Ecto.Schema
  import Ecto.Changeset

  schema "changes" do
    field :action, :string
    field :name, :string
    field :description, :string
    field :project_tags, {:array, :string}

    belongs_to :team, PmTool.Teams.Team
    belongs_to :user, PmTool.Accounts.User
    belongs_to :task, PmTool.Tasks.Task

    timestamps()
  end

  @doc false
  def changeset(change, attrs) do
    change
    |> cast(attrs, [:action, :name, :team_id, :user_id, :task_id, :project_tags, :description])
    |> validate_required([:action, :name, :user_id, :description])
  end
end
