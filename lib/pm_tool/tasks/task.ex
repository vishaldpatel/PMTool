defmodule PmTool.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs
  alias PmTool.Tasks
  alias PmTool.Accounts.User
  alias PmTool.Teams.Team

  @stages ["backlog", "upcoming", "current", "done"]
  @statuses ["unstarted", "started", "finished", "delivered", "rejected", "acceped"]
  def statuses, do: @statuses
  def stages, do: @stages

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :stage, :string
    field :status, :string
    field :slug, :string
    field :task_order, :integer

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
    |> cast(attrs, [:name, :description, :stage, :status, :creator_id, :owner_id, :team_id, :project_id, :task_order])
    |> validate_required([:name, :creator_id])
    |> slugify()
    |> unique_constraint(:slug)
    |> maybe_set_stage()
    |> maybe_set_status()
    |> validate_inclusion(:stage, @stages)
    |> validate_inclusion(:status, @statuses)
    |> maybe_set_task_order()
    |> validate_required([:stage, :status, :task_order])
  end

  defp maybe_set_task_order(changeset) do
    if get_field(changeset, :task_order) == nil do
      team_id = get_field(changeset, :team_id)
      stage = case get_field(changeset, :stage) do
        nil -> "backlog"
        stage -> stage
      end
      creator_id = get_field(changeset, :creator_id)

      new_task_order =
        if (team_id != nil) do
          case Tasks.get_max_task_order_for(%Team{id: team_id}, stage) do
            nil -> 1
            num ->  num + 1
          end
        else
          case Tasks.get_max_task_order_for(%User{id: creator_id}, stage) do
            nil -> 1
            num -> num + 1
          end
        end
      put_change(changeset, :task_order, new_task_order)
    else
      changeset
    end
  end

  defp maybe_set_status(changeset) do
    if get_field(changeset, :status) == nil do
      put_change(changeset, :status, "unstarted")
    else
      changeset
    end
  end

  defp maybe_set_stage(changeset) do
    if get_field(changeset, :stage) == nil do
      put_change(changeset, :stage, "backlog")
    else
      changeset
    end
  end
end
