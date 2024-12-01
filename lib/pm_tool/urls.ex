defmodule PmTool.URLs do
  import Ecto.Changeset

  defp hex_now() do
    DateTime.utc_now()
    |> DateTime.to_unix(:millisecond)
    |> Integer.to_string(16)
  end

  def slugify(changeset) do
    if get_field(changeset, :slug) == nil do
      url_slug = get_field(changeset, :name) || ""

      url_slug = String.downcase(url_slug)
      |> String.replace(~r/[^a-zA-Z0-9 &]/, "")
      |> String.replace("&", "and")
      |> String.split()
      |> Enum.join("-")

      url_slug = "#{hex_now()}-#{url_slug}"
      put_change(changeset, :slug, url_slug)
    else
      changeset
    end
  end
end

