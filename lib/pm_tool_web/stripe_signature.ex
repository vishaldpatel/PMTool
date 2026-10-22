defmodule PmToolWeb.StripeSignature do
  @moduledoc """
  Verifies the `Stripe-Signature` header sent with webhook events.

  See https://docs.stripe.com/webhooks#verify-manually
  """

  # Reject events signed more than five minutes ago, to limit replay attacks.
  @tolerance_seconds 300

  @doc """
  Checks that `payload` was signed with `secret`, given the value of the
  `Stripe-Signature` header.

  ## Examples

      iex> verify(payload, header, secret)
      :ok

      iex> verify(payload, "t=1,v1=bad", secret)
      {:error, :expired}
  """
  def verify(payload, header, secret, now \\ System.system_time(:second))
  def verify(_payload, _header, nil, _now), do: {:error, :no_secret}
  def verify(_payload, nil, _secret, _now), do: {:error, :no_signature}

  def verify(payload, header, secret, now) do
    with {:ok, timestamp, signatures} <- parse(header),
         :ok <- check_timestamp(timestamp, now) do
      expected = sign(payload, timestamp, secret)

      if Enum.any?(signatures, &Plug.Crypto.secure_compare(&1, expected)),
        do: :ok,
        else: {:error, :invalid_signature}
    end
  end

  @doc """
  Computes the `v1` signature Stripe would send for `payload` at `timestamp`.
  """
  def sign(payload, timestamp, secret) do
    :crypto.mac(:hmac, :sha256, secret, "#{timestamp}.#{payload}")
    |> Base.encode16(case: :lower)
  end

  defp parse(header) do
    parts = header |> String.split(",") |> Enum.map(&String.split(&1, "=", parts: 2))
    timestamps = for ["t", t] <- parts, do: t
    signatures = for ["v1", signature] <- parts, do: signature

    with [timestamp] <- timestamps,
         [_ | _] <- signatures,
         {timestamp, ""} <- Integer.parse(timestamp) do
      {:ok, timestamp, signatures}
    else
      _ -> {:error, :invalid_header}
    end
  end

  defp check_timestamp(timestamp, now) do
    if abs(now - timestamp) <= @tolerance_seconds, do: :ok, else: {:error, :expired}
  end
end
