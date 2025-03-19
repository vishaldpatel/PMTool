defmodule PmToolWeb.SubscriptionComponent do
  use PmToolWeb, :live_component

  alias PmTool.Accounts
  alias PmTool.Accounts.User

  def mount(socket) do
    {:ok,
     assign(socket,
       trial_actions_left: 0,
       action_count: 0,
       can_canel: false
     )}
  end

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    trial_actions_left = User.max_trial_actions() - socket.assigns.action_count

    socket =
      socket
      |> assign(trial_actions_left: trial_actions_left)
      |> assign(
        sub_button_color:
          case trial_actions_left do
            y when y > 100 ->
              "bg-gray-600 hover:bg-lime-500"

            y when y > 50 ->
              "bg-yellow-700 hover:bg-lime-500"

            y when y > 0 ->
              "bg-lime-600 hover:bg-lime-500"

            y when y <= 0 ->
              "bg-orange-700 hover:bg-lime-500"
          end
      )

    {:ok, socket}
  end

  def handle_event("reinstate_subscription", _, socket) do
    Application.fetch_env!(:pm_tool, :STRIPE_API_KEY) |> IO.inspect()
    Accounts.reinstate_subscription_for(socket.assigns.current_user)

    {:noreply,
     assign(socket,
       subscription: Accounts.get_subscription(socket.assigns.current_user),
       can_canel: true
     )}
  end

  def handle_event("cancel_subscription", _, socket) do
    Application.fetch_env!(:pm_tool, :STRIPE_API_KEY) |> IO.inspect()
    Accounts.cancel_subscription_for(socket.assigns.current_user)

    {:noreply,
     assign(socket, subscription: Accounts.get_subscription(socket.assigns.current_user))}
  end

  def active_subscription(assigns) do
    ~H"""
    <div></div>
    """
  end

  def cancelable_subscription(assigns) do
    ~H"""
    <div id={@id}>
      <div class="text-cyan-800">You currently have an active subscription.</div>
      <button
        id="cancel_subscription"
        phx-click={JS.toggle(to: "#confirm_cancellation") |> JS.toggle(to: "#cancel_subscription")}
        class="font-bold rounded my-1 px-2 mr-1 text-gray-100 bg-red-500 hover:bg-red-700 rounded p-[1px]"
      >
        Cancel Subscription
      </button>
      <form phx-submit="cancel_subscription" phx-target={@myself} class="inline-block">
        <button
          id="confirm_cancellation"
          class="font-bold rounded my-1 px-2 mr-1 text-gray-100 bg-red-500 hover:bg-red-700 rounded p-[1px] hidden"
        >
          Confirm Cancellation
        </button>
      </form>
    </div>
    """
  end

  def cancelled_subscription(assigns) do
    ~H"""
    <div id={@id} class="mt-4 text-center bg-gray-800 p-1 pb-2">
      <div class="bold text-sm text-gray-200 mt-1 uppercase">
        Subscription ends in {@subscription.current_period_ends_at
        |> DateTime.to_date()
        |> Date.diff(Date.utc_today())} days
      </div>
      <form phx-submit="reinstate_subscription" phx-target={@myself}>
        <button class={"font-bold rounded my-1 px-2 mr-1 text-gray-100 #{@sub_button_color} rounded p-[1px]"}>
          Reinstate Subscription
        </button>
      </form>
    </div>
    """
  end

  def trial_subscription(assigns) do
    ~H"""
    <div id={@id} class="mt-4 text-center bg-gray-800 p-1 pb-2">
      <div class="bold text-sm text-gray-200 mt-1 uppercase">
        <%= if @trial_actions_left <= 0 do %>
          Trial Actions Limit Reached
        <% else %>
          {@trial_actions_left} Actions Remaining in Trial
        <% end %>
      </div>
      <a href="https://buy.stripe.com/test_3cs7vJ72WdGM5kQ8ww" target="_blank">
        <button class={"font-bold rounded my-1 px-2 mr-1 text-gray-100 #{@sub_button_color} rounded p-[1px]"}>
          Upgrade Subscription
        </button>
      </a>
    </div>
    """
  end

  def render(assigns) do
    subscription = assigns.subscription

    if assigns.subscription do
      cond do
        subscription.status == "active" and subscription.cancel_at_period_end ->
          cancelled_subscription(assigns)

        subscription.status == "active" and assigns.can_cancel ->
          cancelable_subscription(assigns)

        subscription.status == "active" ->
          active_subscription(assigns)

        true ->
          trial_subscription(assigns)
      end
    else
      trial_subscription(assigns)
    end
  end
end
