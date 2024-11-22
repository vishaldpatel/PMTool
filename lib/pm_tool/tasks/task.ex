defmodule PmTool.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs

  @stages ["backlog", "upcoming", "current", "done"]
  @statuses ["unstarted", "started", "finished", "delivered", "rejected", "acceped"]

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :stage, :string
    field :status, :string
    field :slug, :string

    belongs_to :creator, PmTool.Accounts.User
    belongs_to :owner, PmTool.Accounts.User
    belongs_to :team, PmTool.Teams.Team
    belongs_to :project, PmTool.Projects.Project

    has_many :blockers, PmTool.Tasks.Blocker
    has_many :comments, PmTool.Comments.TaskComment

    timestamps()    
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :description, :stage, :status, :creator_id, :owner_id, :team_id, :project_id])
    |> validate_required([:name, :stage, :status, :creator_id, :team_id])
    |> slugify()
    |> unique_constraint(:slug)
    |> validate_inclusion(:stage, @stages)
    |> validate_inclusion(:status, @statuses)
  end
end
