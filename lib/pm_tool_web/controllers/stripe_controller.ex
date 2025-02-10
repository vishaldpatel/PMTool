defmodule PmToolWeb.StripeController do
  use PmToolWeb, :controller
  alias PmTool.Accounts

  def webhook(conn, params) do
    stripe_id = params["data"]["object"]["id"]
    event_type = params["type"]

    case event_type do
      "customer.created" ->
        email = params["data"]["object"]["email"]
        user = PmTool.Accounts.get_user_by_email(email)
        Accounts.update_user_stripe_customer_id(user, stripe_id)

      "customer.subscription.created" ->
        customer_id = params["data"]["object"]["customer"]
        plan = params["data"]["object"]["plan"]["id"]
        status = params["data"]["object"]["status"]

        current_period_started_at =
          DateTime.from_unix!(params["data"]["object"]["current_period_start"])

        current_period_ends_at =
          DateTime.from_unix!(params["data"]["object"]["current_period_end"])

        PmTool.Accounts.create_subscription(%{
          stripe_id: stripe_id,
          stripe_customer_id: customer_id,
          plan: plan,
          status: status,
          current_period_started_at: current_period_started_at,
          current_period_ends_at: current_period_ends_at,
          cancel_at_period_end: false
        })

      "customer.subscription.updated" ->
        subscription = Accounts.get_subscription_by_stripe_id(stripe_id)
        status = params["data"]["object"]["status"]
        cancel_at_period_end = params["data"]["object"]["cancel_at_period_end"]

        current_period_started_at =
          DateTime.from_unix!(params["data"]["object"]["current_period_start"])

        current_period_ends_at =
          DateTime.from_unix!(params["data"]["object"]["current_period_end"])

        if subscription do
          Accounts.update_subscription(
            subscription,
            %{
              status: status,
              current_period_started_at: current_period_started_at,
              current_period_ends_at: current_period_ends_at,
              cancel_at_period_end: cancel_at_period_end
            }
          )
        end

      "customer.subscription.deleted" ->
        subscription = Accounts.get_subscription_by_stripe_id(stripe_id)
        status = params["data"]["object"]["status"]

        if subscription do
          Accounts.update_subscription(
            subscription,
            %{status: status}
          )
        end

      event_type ->
        IO.inspect("Ignored Stripe Event: #{event_type}")
    end

    conn
    |> send_resp(200, "OK")
    |> halt()
  end
end
