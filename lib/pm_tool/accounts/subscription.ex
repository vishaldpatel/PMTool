defmodule PmTool.Accounts.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subscriptions" do
    field :plan, :string
    field :stripe_id, :string
    field :stripe_customer_id, :string
    field :status, :string
    field :current_period_started_at, :utc_datetime
    field :current_period_ends_at, :utc_datetime
    field :cancel_at_period_end, :boolean
    timestamps()
  end

  @doc false
  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [
      :plan,
      :stripe_id,
      :stripe_customer_id,
      :status,
      :current_period_started_at,
      :current_period_ends_at,
      :cancel_at_period_end
    ])
    |> validate_required([:stripe_id, :status])
  end
end
