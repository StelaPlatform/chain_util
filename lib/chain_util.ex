defmodule ChainUtil do
  @moduledoc """
  Documentation for `ChainUtil`.
  """

  @doc """
  Return wallets for development and testing.


  iex> ChainUtil.wallets()
  %{
    alice: %{
      addr: "0xa94f5374Fce5edBC8E2a8697C15331677e6EbF0B",
      sk: "0x45a915e4d060149eb4365960e6a7a45f334393093061116b197e3240065ff2d8"
    },
    bob: %{
      addr: "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",
      sk: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
    },
    ...
  }
  """
  def wallets do
    :chain_util
    |> Application.get_env(:wallets)
    |> Enum.into(%{}, fn {name, {addr, sk}} -> {name, %{addr: addr, sk: sk}} end)
  end
end
