defmodule PmToolWeb.StripeSignatureTest do
  use ExUnit.Case, async: true

  alias PmToolWeb.StripeSignature

  @secret "whsec_test"
  @payload ~s({"type":"customer.created"})
  @now 1_700_000_000

  defp header(payload \\ @payload, timestamp \\ @now, secret \\ @secret) do
    "t=#{timestamp},v1=#{StripeSignature.sign(payload, timestamp, secret)}"
  end

  test "accepts a valid signature" do
    assert StripeSignature.verify(@payload, header(), @secret, @now) == :ok
  end

  test "accepts a valid signature among several" do
    header = "t=#{@now},v1=deadbeef,v1=#{StripeSignature.sign(@payload, @now, @secret)}"
    assert StripeSignature.verify(@payload, header, @secret, @now) == :ok
  end

  test "rejects a signature made with another secret" do
    assert StripeSignature.verify(@payload, header(@payload, @now, "whsec_other"), @secret, @now) ==
             {:error, :invalid_signature}
  end

  test "rejects a tampered payload" do
    assert StripeSignature.verify(~s({"type":"x"}), header(), @secret, @now) ==
             {:error, :invalid_signature}
  end

  test "rejects an old timestamp" do
    assert StripeSignature.verify(@payload, header(), @secret, @now + 301) == {:error, :expired}
  end

  test "rejects malformed or missing headers" do
    assert StripeSignature.verify(@payload, "garbage", @secret, @now) == {:error, :invalid_header}

    assert StripeSignature.verify(@payload, "t=#{@now}", @secret, @now) ==
             {:error, :invalid_header}

    assert StripeSignature.verify(@payload, nil, @secret, @now) == {:error, :no_signature}
  end

  test "rejects everything when no secret is configured" do
    assert StripeSignature.verify(@payload, header(), nil, @now) == {:error, :no_secret}
  end
end
