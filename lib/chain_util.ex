defmodule ChainUtil do
  @doc """
  Return wallets for development and testing.
  """

  def wallets do
    case Application.get_env(:chain_util, :chain, :erigon) do
      :erigon -> erigon_wallets()
      :hardhat -> hardhat_wallets()
    end
  end

  def erigon_wallets do
    %{
      deployer: %{
        addr: "0x67b1d87101671b127f5f8714789C7192f7ad340e",
        sk: "0x26e86e45f6fc45ec6e2ecd128cec80fa1d1505e5507dcd2ae58c3130a7a97b48"
      },
      alice: %{
        addr: "0xa94f5374Fce5edBC8E2a8697C15331677e6EbF0B",
        sk: "0x45a915e4d060149eb4365960e6a7a45f334393093061116b197e3240065ff2d8"
      },
      bob: %{
        addr: "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc",
        sk: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
      },
      charley: %{
        addr: "0x90f79bf6eb2c4f870365e785982e1f101e93b906",
        sk: "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
      },
      david: %{
        addr: "0x15d34aaf54267db7d7c367839aaf71a00a2c6a65",
        sk: "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
      },
      emma: %{
        addr: "0x9965507d1a55bcc2695c58ba16fb37d819b0a4dc",
        sk: "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"
      },
      frank: %{
        addr: "0x976ea74026e726554db657fa54763abd0c3a0aa9",
        sk: "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e"
      },
      greg: %{
        addr: "0x14dc79964da2c08b23698b3d3cc7ca32193d9955",
        sk: "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356"
      },
      helen: %{
        addr: "0x23618e81e3f5cdf7f54c3d65f7fbc0abf5b21e8f",
        sk: "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97"
      },
      issac: %{
        addr: "0xa0ee7a142d267c1f36714e4a8f75612f20a79720",
        sk: "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"
      },
      jack: %{
        addr: "0xbcd4042de499d14e55001ccbb24a551f3b954096",
        sk: "0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897"
      }
    }
  end

  def hardhat_wallets do
    %{
      deployer: %{
        addr: "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
        sk: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
      },
      alice: %{
        addr: "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        sk: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
      },
      bob: %{
        addr: "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        sk: "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
      },
      charley: %{
        addr: "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
        sk: "0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6"
      },
      david: %{
        addr: "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
        sk: "0x47e179ec197488593b187f80a00eb0da91f1b9d0b13f8733639f19c30a34926a"
      },
      emma: %{
        addr: "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc",
        sk: "0x8b3a350cf5c34c9194ca85829a2df0ec3153be0318b5e2d3348e872092edffba"
      },
      frank: %{
        addr: "0x976EA74026E726554dB657fA54763abd0C3a0aa9",
        sk: "0x92db14e403b83dfe3df233f83dfa3a0d7096f21ca9b0d6d6b8d88b2b4ec1564e"
      },
      greg: %{
        addr: "0x14dC79964da2C08b23698B3D3cc7Ca32193d9955",
        sk: "0x4bbbf85ce3377467afe5d46f804f221813b2bb87f24d81f60f1fcdbf7cbf4356"
      },
      helen: %{
        addr: "0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f",
        sk: "0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97"
      },
      issac: %{
        addr: "0xa0Ee7A142d267C1f36714E4a8F75612F20a79720",
        sk: "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"
      },
      jack: %{
        addr: "0xBcd4042DE499D14e55001CcbB24a551F3b954096",
        sk: "0xf214f2b2cd398c806f84e317254e0f0b801d0643303237d97a22a48e01628897"
      }
    }
  end

  def hex_to_binary("0x" <> hex), do: hex_to_binary(hex)

  def hex_to_binary(hex) do
    case String.printable?(hex) do
      true -> Base.decode16!(hex, case: :mixed)
      false -> hex
    end
  end

  def binary_to_hex("0x" <> bin), do: "0x" <> bin

  def binary_to_hex(bin) do
    case String.printable?(bin) do
      true -> "0x" <> bin
      false -> "0x" <> Base.encode16(bin, case: :lower)
    end
  end
end
