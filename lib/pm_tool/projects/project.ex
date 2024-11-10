defmodule PmTool.Projects.Project do
  use Ecto.Schema
  import Ecto.Changeset

  schema "projects" do
    field :name, :string
    field :description, :string
    field :url_slug, :string
    field :url_hash, :string
    belongs_to :owner, PmTool.Users.User

    timestamps()
  end

  def get_combo_slug(project) do
    "#{project.url_hash}--#{project.url_slug}"
  end

  @doc false
  def changeset(project, attrs) do
    project
    |> cast(attrs, [:name,:owner_id, :description])
    |> validate_required([:name])
    |> generate_url_hash()
    |> unique_constraint(:url_hash)
    |> slugify()
  end

  def generate_url_hash(changeset) do
    if get_field(changeset, :url_hash) == nil do
      url_hash = Ecto.UUID.generate()
      put_change(changeset, :url_hash, url_hash)
    else
      changeset
    end
  end

  def slugify(changeset) do
    if get_field(changeset, :url_slug) == nil do
      url_slug = get_field(changeset, :name) || ""

      url_slug = String.downcase(url_slug)
      |> String.replace(~r/[^a-zA-Z0-9 &]/, "")
      |> String.replace("&", "and")
      |> String.split()
      |> Enum.join("-")
      put_change(changeset, :url_slug, url_slug)
    else
      changeset
    end
  end
end

defimpl Phoenix.Param, for: PmTool.Projects.Project do
  def to_param(%{url_hash: url_hash, url_slug: url_slug}) do
    "#{url_hash}--#{url_slug}"
  end
end
