defmodule PmTool.Tasks.Task do
  use Ecto.Schema
  import PmTool.URLs
  import Ecto.Changeset

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :url_hash, :string

    belongs_to :project, PmTool.Projects.Project
    belongs_to :creator, PmTool.Accounts.User
    belongs_to :owner, PmTool.Accounts.User
    belongs_to :status, PmTool.Tasks.TaskStatus, foreign_key: :current_status_id
    belongs_to :stage, PmTool.Tasks.Stage, foreign_key: :current_stage_id
    belongs_to :epic, PmTool.Projects.Epic, foreign_key: :epic_id

    has_many :task_statuses, PmTool.Tasks.TaskStatus
    has_many :stages, PmTool.Tasks.Stage
    has_many :blockers, PmTool.Tasks.Blocker

    timestamps()
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:project_id, :creator_id, :owner_id, :name, :description, :current_status_id, :current_stage_id, :epic_id])
    |> validate_required([:project_id, :creator_id, :name])
    |> generate_url_hash()
    |> unique_constraint(:url_hash)
  end
end

defimpl Phoenix.Param, for: PmTool.Tasks.Task do
  def to_param(%{url_hash: url_hash}) do
    url_hash
  end
end
