defmodule PmTool.Teams.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset
  import Exgravatar

  @roles ["owner", "admin", "member"]

  schema "team_members" do
    field :role, :string
    field :name, :string
    field :email, :string

    belongs_to :team, PmTool.Teams.Team
    belongs_to :user, PmTool.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:role, :team_id, :user_id, :name, :email])
    |> validate_required([:team_id, :email, :role])
    |> unique_constraint([:team_id, :email], name: :team_members_team_id_email_index)
    |> validate_inclusion(:role, @roles)
    |> maybe_make_a_thumbnail()
  end

  defp maybe_make_a_thumbnail(changeset) do
    if changed?(changeset, :email) or changed?(changeset, :name) do
      # Create a thumbnail for the email and store it in the assets directory
      email = get_field(changeset, :email)
      url = gravatar_url(email, s: 100, d: "monsterid")

      case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          File.write!("priv/static/images/team_members/#{email}.png", body)

        _ ->
          nil
      end

      changeset
    end
  end
end
