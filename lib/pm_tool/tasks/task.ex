defmodule PmTool.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs
  alias PmTool.Tasks
  alias PmTool.Accounts.User
  alias PmTool.Teams.Team

  @stages ["Later", "Now"]
  @statuses [
    "Unappraised",
    "Unstarted",
    "Started",
    "Finished",
    "Delivered",
    "Rejected",
    "Accepted",
    "Closed"
  ]
  @estimates [1, 2, 4, 6, 8, 12, 16, 24, 60]
  @estimates_for_select [1, 2, 4, 6, 8, 12, 16, 24, 60]

  def estimates_for_select, do: @estimates_for_select
  def estimates, do: @estimates
  def statuses, do: @statuses
  def stages, do: @stages

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :stage, :string
    field :status, :string
    field :slug, :string
    field :task_order, :integer
    field :estimate, :integer
    field :status_updated_at, :utc_datetime

    belongs_to :creator, PmTool.Accounts.User
    belongs_to :owner, PmTool.Accounts.User
    belongs_to :team, PmTool.Teams.Team

    has_many :blockers, PmTool.Tasks.Blocker
    has_many :comments, PmTool.Comments.TaskComment
    many_to_many :projects, PmTool.Projects.Project, join_through: PmTool.Projects.ProjectTask

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :name,
      :description,
      :stage,
      :status,
      :creator_id,
      :owner_id,
      :team_id,
      :task_order,
      :estimate
    ])
    |> validate_required([:name, :creator_id])
    |> slugify()
    |> unique_constraint(:slug)
    |> maybe_set_stage()
    |> maybe_set_status()
    |> validate_inclusion(:stage, @stages)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:estimate, @estimates)
    |> maybe_set_estimate()
    |> maybe_set_task_order()
    |> maybe_set_status_updated_at()
    |> validate_required([:stage, :status, :task_order])
  end

  defp maybe_set_status_updated_at(changeset) do
    # If status is changed, set status_updated_at
    if get_field(changeset, :status) != get_field(changeset, :previous_status) do
      truncated_time = DateTime.truncate(DateTime.utc_now(), :second)
      put_change(changeset, :status_updated_at, truncated_time)
    else
      changeset
    end
  end

  defp maybe_set_task_order(changeset) do
    if get_field(changeset, :task_order) == nil or changed?(changeset, :stage) do
      team_id = get_field(changeset, :team_id)

      stage =
        case get_field(changeset, :stage) do
          nil -> "Later"
          stage -> stage
        end

      creator_id = get_field(changeset, :creator_id)

      new_task_order =
        if team_id != nil do
          case Tasks.get_max_task_order_for(%Team{id: team_id}, stage) do
            nil -> 1
            num -> num + 1
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

  def maybe_set_estimate(changeset) do
    if get_field(changeset, :status) == "Unappraised" and changed?(changeset, :status) do
      put_change(changeset, :estimate, 0)
    else
      changeset
    end
  end

  defp maybe_set_status(changeset) do
    cond do
      get_field(changeset, :estimate) > 0 and changed?(changeset, :estimate) ->
        put_change(changeset, :status, "Unstarted")

      get_field(changeset, :status) == nil ->
        put_change(changeset, :status, "Unappraised")

      true ->
        changeset
    end
  end

  defp maybe_set_stage(changeset) do
    if get_field(changeset, :stage) == nil do
      put_change(changeset, :stage, "Later")
    else
      changeset
    end
  end
end
