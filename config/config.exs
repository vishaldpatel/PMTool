# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :pm_tool,
  ecto_repos: [PmTool.Repo]

# Configures the endpoint
config :pm_tool, PmToolWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: PmToolWeb.ErrorHTML, json: PmToolWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: PmTool.PubSub,
  live_view: [signing_salt: "pVLQIDpT"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :pm_tool, PmTool.Mailer, adapter: Swoosh.Adapters.Local

# The name and address that account emails are sent from.
config :pm_tool, :mail_from, {"PmTool", "noreply@localhost"}

# Stripe billing is disabled unless STRIPE_API_KEY is set (see config/runtime.exs).
config :pm_tool, :stripe, enabled: false

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.2.7",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
