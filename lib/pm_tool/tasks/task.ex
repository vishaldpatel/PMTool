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
    field :tags, {:array, :string}, default: []
    field :project_tags, {:array, :string}, default: []
    field :is_milestone, :boolean, default: false
    field :due_date, :date

    belongs_to :creator, PmTool.Accounts.User
    belongs_to :owner, PmTool.Teams.TeamMember
    belongs_to :team, PmTool.Teams.Team

    has_many :blockers, PmTool.Tasks.Blocker
    has_many :comments, PmTool.Comments.TaskComment

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
      :estimate,
      :project_tags,
      :is_milestone,
      :due_date,
      :tags
    ])
    |> validate_required([:name, :creator_id])
    |> slugify()
    |> unique_constraint(:slug)
    |> maybe_set_stage()
    |> maybe_set_status()
    |> validate_inclusion(:stage, @stages)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:estimate, @estimates)
    |> maybe_set_milestone()
    |> maybe_set_estimate()
    |> maybe_set_task_order()
    |> maybe_set_status_updated_at()
    |> validate_required([:stage, :status, :task_order])
    |> validate_empty_tags(attrs)
    |> validate_empty_project_tags(attrs)
  end

  defp validate_empty_tags(changeset, attrs) do
    if changed?(changeset, :tags) do
      case Map.fetch(attrs, "tags") do
        {:ok, _tags} ->
          changeset

        :error ->
          put_change(changeset, :tags, [])
      end
    else
      changeset
    end
  end

  defp validate_empty_project_tags(changeset, attrs) do
    if changed?(changeset, :project_tags) do
      case Map.fetch(attrs, :project_tags) do
        {:ok, _tags} ->
          changeset

        :error ->
          put_change(changeset, :project_tags, [])
      end
    else
      changeset
    end
  end

  defp maybe_set_milestone(changeset) do
    cond do
      is_nil(changeset.data.is_milestone) and is_nil(get_field(changeset, :is_milestone)) ->
        put_change(changeset, :is_milestone, false)

      true ->
        changeset
    end
  end

  defp maybe_set_status_updated_at(changeset) do
    # If status is changed, set status_updated_at
    if changed?(changeset, :status) do
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
      put_change(changeset, :estimate, 1)
    else
      changeset
    end
  end

  defp maybe_set_status(changeset) do
    cond do
      get_field(changeset, :id) == nil and get_field(changeset, :status) == "Unappraised" ->
        changeset

      changed?(changeset, :estimate) ->
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
