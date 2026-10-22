defmodule PmToolWeb.StripeControllerTest do
  use PmToolWeb.ConnCase, async: false

  alias PmTool.Accounts
  alias PmToolWeb.StripeSignature

  @secret "whsec_test"

  @event Jason.encode!(%{
           type: "customer.subscription.created",
           data: %{
             object: %{
               id: "sub_123",
               customer: "cus_123",
               plan: %{id: "price_123"},
               status: "active",
               current_period_start: 1_700_000_000,
               current_period_end: 1_702_592_000
             }
           }
         })

  defp enable_billing(webhook_secret) do
    previous = Application.get_env(:pm_tool, :stripe)
    on_exit(fn -> Application.put_env(:pm_tool, :stripe, previous) end)

    Application.put_env(:pm_tool, :stripe,
      enabled: true,
      api_key: "sk_test",
      webhook_secret: webhook_secret
    )
  end

  defp post_event(conn, body, signature) do
    conn
    |> put_req_header("content-type", "application/json")
    |> then(&if signature, do: put_req_header(&1, "stripe-signature", signature), else: &1)
    |> post(~p"/api/stripe/webhook", body)
  end

  defp sign(body, secret \\ @secret) do
    timestamp = System.system_time(:second)
    "t=#{timestamp},v1=#{StripeSignature.sign(body, timestamp, secret)}"
  end

  test "is not found when billing is disabled", %{conn: conn} do
    conn = post_event(conn, @event, sign(@event))
    assert response(conn, 404)
    refute Accounts.get_subscription_by_stripe_id("sub_123")
  end

  test "rejects events without a signature", %{conn: conn} do
    enable_billing(@secret)
    conn = post_event(conn, @event, nil)
    assert response(conn, 400)
    refute Accounts.get_subscription_by_stripe_id("sub_123")
  end

  test "rejects events signed with another secret", %{conn: conn} do
    enable_billing(@secret)
    conn = post_event(conn, @event, sign(@event, "whsec_other"))
    assert response(conn, 400)
    refute Accounts.get_subscription_by_stripe_id("sub_123")
  end

  test "rejects events when no webhook secret is configured", %{conn: conn} do
    enable_billing(nil)
    conn = post_event(conn, @event, sign(@event))
    assert response(conn, 400)
    refute Accounts.get_subscription_by_stripe_id("sub_123")
  end

  test "handles correctly signed events", %{conn: conn} do
    enable_billing(@secret)
    conn = post_event(conn, @event, sign(@event))
    assert response(conn, 200) == "OK"

    assert %{status: "active", stripe_customer_id: "cus_123"} =
             Accounts.get_subscription_by_stripe_id("sub_123")
  end
end
