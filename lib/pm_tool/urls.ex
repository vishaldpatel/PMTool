defmodule PmTool.UrlTools do
  import Ecto.Changeset

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

