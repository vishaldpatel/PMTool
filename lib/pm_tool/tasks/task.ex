defmodule PmTool.Tasks.Task do
  use Ecto.Schema
  import PmTool.UrlTools
  import Ecto.Changeset

  schema "tasks" do
    field :name, :string
    field :description, :string
    field :url_slug, :string
    field :url_hash, :string

    belongs_to :project, PmTool.Projects.Project
    belongs_to :creator, PmTool.Accounts.User
    belongs_to :owner, PmTool.Accounts.User
    belongs_to :status, PmTool.Tasks.TaskStatus, foreign_key: :current_status_id
    belongs_to :stage, PmTool.Tasks.Stage, foreign_key: :current_stage_id

    has_many :task_statuses, PmTool.Tasks.TaskStatus
    has_many :stages, PmTool.Tasks.Stage

    timestamps()
  end

  def get_combo_slug(project) do
    "#{project.url_hash}--#{project.url_slug}"
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:project_id, :creator_id, :owner_id, :name, :description, :current_status_id, :current_stage_id])
    |> validate_required([:project_id, :creator_id, :name])
    |> generate_url_hash()
    |> unique_constraint(:url_hash)
    |> slugify()
  end
end

defimpl Phoenix.Param, for: PmTool.Projects.Task do
  def to_param(%{url_hash: url_hash, url_slug: url_slug}) do
    "#{url_hash}--#{url_slug}"
  end
end
