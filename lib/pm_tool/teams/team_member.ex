defmodule PmTool.Teams.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset
  import Exgravatar
  alias PmTool.Teams.Change
  alias PmTool.Teams.Team

  @roles ["owner", "admin", "member"]

  schema "team_members" do
    field :role, :string
    field :name, :string
    field :email, :string
    field :current_user_id, :integer, virtual: true

    belongs_to :team, Team
    belongs_to :user, PmTool.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:role, :team_id, :user_id, :name, :email, :current_user_id])
    |> validate_required([:team_id, :email, :role, :current_user_id])
    |> unique_constraint([:team_id, :email], name: :team_members_team_id_email_index)
    |> validate_inclusion(:role, @roles)
    |> maybe_make_a_thumbnail()
    |> add_history()
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

  defp add_history(changeset) do
    current_user = PmTool.Accounts.get_user!(get_field(changeset, :current_user_id))

    current_team_member =
      if get_field(changeset, :team_id),
        do:
          PmTool.Teams.get_team_member!(%Team{id: get_field(changeset, :team_id)}, current_user),
        else: nil

    prepare_changes(changeset, fn changeset ->
      team = PmTool.Teams.get_team!(get_field(changeset, :team_id))

      description =
        case changeset.action do
          :insert ->
            "#{current_team_member.name} added member #{changeset.changes.name}"

          :update ->
            Enum.reduce(
              changeset.changes,
              "#{current_team_member.name} updated #{changeset.data.name}:",
              fn {key, value}, acc ->
                case key do
                  :current_user_id -> acc
                  _ -> acc <> " #{key} to #{value};"
                end
              end
            )

          :delete ->
            "#{get_field(changeset, :name)} removed member #{team.name}"

          _ ->
            nil
        end

      changeset.repo.insert!(%Change{
        action: "#{changeset.action}",
        name: changeset.data.name || get_field(changeset, :name),
        team_id: get_field(changeset, :team_id),
        user_id: get_field(changeset, :current_user_id),
        description: description
      })

      changeset
    end)
  end
end
