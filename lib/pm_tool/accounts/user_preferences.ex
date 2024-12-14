defmodule PmTool.Accounts.UserPreferences do
  use Ecto.Schema
  import Ecto.Changeset

  alias PmTool.Accounts.User

  schema "user_preferences" do
    belongs_to :user, User
    field :preferences, :map

    timestamps()
  end

  @doc false
  def changeset(user_preferences, attrs) do
    user_preferences
    |> cast(attrs, [:user_id, :preferences])
    |> validate_required([:user_id, :preferences])
  end
end
