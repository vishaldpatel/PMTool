defmodule PmTool.Repo do
  use Ecto.Repo,
    otp_app: :pm_tool,
    adapter: Ecto.Adapters.SQLite3
end
