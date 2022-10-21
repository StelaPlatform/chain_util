defmodule ChainUtil.DeployerGen do
  require UtilityBelt.CodeGen.DynamicModule
  alias UtilityBelt.CodeGen.DynamicModule

  def gen_deployer(contract_json_path, contract_name, module_name) do
    contract_module = String.to_atom("Elixir.#{contract_name}")

    [constructor] =
      contract_json_path
      |> File.read!()
      |> Poison.decode!()
      |> Map.get("abi")
      |> Enum.filter(fn abi -> abi["type"] == "constructor" end)

    args = constructor["inputs"] |> Enum.map(&Map.get(&1, "name"))
    types = constructor["inputs"] |> Enum.map(&Map.get(&1, "type"))
    arg_type_list = Enum.zip(args, types)
    quoted_args = args |> Enum.map(&to_snake_atom/1) |> Enum.map(&Macro.var(&1, nil))

    preamble =
      quote do
        alias unquote(contract_module), as: Contract
        use Mix.Task
      end

    inspectors = quote_args_inspect(arg_type_list)

    contents = quote_deployer(quoted_args, inspectors)

    DynamicModule.gen(
      module_name,
      preamble,
      contents,
      doc: "This is auto generated deployer, supported args: #{inspect(arg_type_list)}",
      path: Path.join(File.cwd!(), "lib/mix/tasks")
    )
  end

  # {
  #   "inputs": [
  #     {
  #       "internalType": "uint8",
  #       "name": "digits",
  #       "type": "uint8"
  #     }
  #   ],
  #   "stateMutability": "nonpayable",
  #   "type": "constructor"
  # }
  def quote_deployer(quoted_args, inspectors) do
    quote do
      def run(command_line_args) do
        Application.ensure_all_started(:ocap_rpc)
        %{deployer: %{sk: sk}} = ChainUtil.wallets()

        do_run(command_line_args, sk)
      end

      def do_run([unquote_splicing(quoted_args)], sk) do
        hash = Contract.deploy(sk, unquote_splicing(quoted_args))

        tx = wait_tx(hash) |> IO.inspect(label: "Deployment Transaction")

        contract_address =
          get_contract_address(tx)
          |> IO.inspect(label: "contract address")

        unquote_splicing(inspectors)
      end

      defp get_contract_address(tx) do
        [trace] = tx.traces
        trace.result_address
      end

      defp wait_tx(hash) do
        wait_tx(hash, OcapRpc.Eth.Transaction.get_by_hash(hash))
      end

      defp wait_tx(hash, nil) do
        Process.sleep(1000)
        tx = OcapRpc.Eth.Transaction.get_by_hash(hash)
        wait_tx(hash, tx)
      end

      defp wait_tx(_hash, tx) do
        tx
      end
    end
  end

  def quote_args_inspect(arg_type_list) do
    Enum.map(arg_type_list, &do_quote_args_inspect/1)
  end

  def do_quote_args_inspect({arg, type}) do
    quote do
      Contract
      |> apply(unquote(to_snake_atom("get_" <> arg)), [contract_address])
      |> String.replace("0x", "")
      |> Base.decode16!()
      |> ABI.TypeDecoder.decode(%ABI.FunctionSelector{
        function: nil,
        types: [unquote(get_function_selector_type(type))]
      })
      |> IO.inspect(label: unquote(arg))
    end
  end

  def get_function_selector_type("uint8"), do: {:uint, 8}
  def get_function_selector_type("uint256"), do: {:uint, 256}
  def get_function_selector_type("bool"), do: :bool
  def get_function_selector_type("bytes"), do: :bytes
  def get_function_selector_type("string"), do: :string
  def get_function_selector_type("address"), do: :address

  @doc """
  Convert a string to an atom in snake case.

  ## Examples

    iex> ContractGen.to_snake_atom("getApproved")
    :get_approved

    iex> ContractGen.to_snake_atom("approved")
    :approved
  """
  def to_snake_atom(str) do
    str |> Macro.underscore() |> String.to_atom()
  end
end
