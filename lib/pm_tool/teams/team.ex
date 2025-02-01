defmodule PmTool.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset
  import PmTool.URLs
  alias PmTool.Teams.Change

  schema "teams" do
    field :name, :string
    field :slug, :string
    field :current_user_id, :integer, virtual: true

    belongs_to :owner, PmTool.Accounts.User, foreign_key: :owner_id
    has_many :team_members, PmTool.Teams.TeamMember
    has_many :changes, PmTool.Teams.Change

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :owner_id, :current_user_id])
    |> validate_required([:name, :owner_id, :current_user_id])
    |> slugify()
    |> unique_constraint(:slug)
    |> add_history()
  end

  defp add_history(changeset) do
    prepare_changes(changeset, fn changeset ->
      description =
        case changeset.action do
          :insert -> "Created team #{changeset.changes.name}"
          :update -> "Updated team name to #{changeset.changes.name}"
          _ -> nil
        end

      changeset.repo.insert!(%Change{
        action: "#{changeset.action}",
        name: changeset.data.name || get_field(changeset, :name),
        team_id: get_field(changeset, :id),
        user_id: get_field(changeset, :current_user_id),
        description: description
      })

      changeset
    end)
  end
end
