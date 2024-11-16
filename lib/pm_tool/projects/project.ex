defmodule PmTool.Projects.Project do
  use Ecto.Schema
  import PmTool.URLs
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :description, :string
    field :url_slug, :string
    field :url_hash, :string

    belongs_to :owner, PmTool.Accounts.User
    has_many :members, {"members", PmTool.Accounts.User}, foreign_key: :user_id
    has_many :tasks, PmTool.Tasks.Task

    timestamps()
  end

  def get_combo_slug(project) do
    "#{project.url_hash}--#{project.url_slug}"
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name,:owner_id, :description])
    |> validate_required([:name, :owner_id])
    |> generate_url_hash()
    |> unique_constraint(:url_hash)
    |> slugify()
  end
end

defimpl Phoenix.Param, for: PmTool.Projects.Project do
  def to_param(%{url_hash: url_hash, url_slug: url_slug}) do
    "#{url_hash}--#{url_slug}"
  end
end
