defmodule PmToolWeb.CacheBodyReader do
  @moduledoc """
  Keeps a copy of the raw request body of Stripe webhooks in
  `conn.assigns.raw_body`, since their signature is computed over the exact
  bytes that were sent. Other requests are read as usual.
  """

  def read_body(%Plug.Conn{request_path: "/api/stripe/webhook"} = conn, opts) do
    with {status, body, conn} when status in [:ok, :more] <- Plug.Conn.read_body(conn, opts) do
      conn = update_in(conn.assigns[:raw_body], &[body | &1 || []])
      {status, body, conn}
    end
  end

  def read_body(conn, opts), do: Plug.Conn.read_body(conn, opts)

  @doc """
  Returns the raw body cached by `read_body/2`.
  """
  def raw_body(conn) do
    conn.assigns |> Map.get(:raw_body, []) |> Enum.reverse() |> IO.iodata_to_binary()
  end
end
