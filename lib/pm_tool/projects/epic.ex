defmodule PmTool.Projects.Epic do
  use Ecto.Schema
  import PmTool.URLs
  import Ecto.Changeset

  schema "epics" do
    field :name, :string
    field :description, :string
    field :url_hash, :string
    belongs_to :project, PmTool.Projects.Project
    has_many :tasks, PmTool.Tasks.Task

    timestamps()
  end

  @doc false
  def changeset(epic, attrs) do
    epic
    |> cast(attrs, [:name, :description, :project_id])
    |> validate_required([:name, :project_id])
    |> generate_url_hash()
    |> unique_constraint(:url_hash)
  end
end

defimpl Phoenix.Param, for: PmTool.Projects.Epic do
  def to_param(%{url_hash: url_hash}) do
    url_hash
  end
end
