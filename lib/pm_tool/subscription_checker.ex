defmodule PmTool.SubscriptionChecker do
  use GenServer
  alias PmTool.Accounts

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # Schedule work to be performed at some point
    schedule_work()
    {:ok, state}
  end

  def handle_info(:work, state) do
    # Do the work you desire here
    Accounts.renew_subscription_info_for_users_that_need_it()
    # Reschedule once more
    schedule_work()
    {:noreply, state}
  end

  defp schedule_work() do
    # In 24 hours
    Process.send_after(self(), :work, 24 * 60 * 60 * 1000)
  end
end
