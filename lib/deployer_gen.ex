defmodule ChainUtil.DeployerGen do
  require UtilityBelt.CodeGen.DynamicModule
  alias UtilityBelt.CodeGen.DynamicModule

  def gen_deployer(contract_json_path, contract_name, module_name) do
    contract_module = String.to_atom("Elixir.#{contract_name}")

    preamble =
      quote do
        alias unquote(contract_module), as: Contract
        use Mix.Task
      end

    constructor =
      contract_json_path
      |> File.read!()
      |> Poison.decode!()
      |> Map.get("abi")
      |> Enum.filter(fn abi -> abi["type"] == "constructor" end)
      |> List.first()

    quoted_do_run = quote_do_run(constructor)
    contents = quote_deployer(quoted_do_run)
    doc = get_doc(constructor)

    DynamicModule.gen(
      module_name,
      preamble,
      contents,
      doc: doc,
      path: Path.join(File.cwd!(), "lib/mix/tasks")
    )
  end

  def quote_deployer(quoted_do_run) do
    quote do
      def run(command_line_args) do
        Application.ensure_all_started(:ocap_rpc)
        %{deployer: %{sk: sk}} = ChainUtil.wallets()

        do_run(command_line_args, sk)
      end

      unquote(quoted_do_run)

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
  defp quote_do_run(%{"inputs" => inputs}) do
    args = inputs |> Enum.map(&Map.get(&1, "name"))
    types = inputs |> Enum.map(&Map.get(&1, "type"))
    arg_type_list = Enum.zip(args, types)
    quoted_args = args |> Enum.map(&to_snake_atom/1) |> Enum.map(&Macro.var(&1, nil))
    casts = quote_args_cast(arg_type_list)
    inspectors = quote_args_inspect(arg_type_list)
    default_beneficiary = quote_default_beneficiary(args)

    quote_do_run(quoted_args, casts, inspectors, default_beneficiary)
  end

  defp quote_do_run(quoted_args, casts, inspectors, nil) do
    quote do
      def do_run([unquote_splicing(quoted_args)], sk) do
        unquote_splicing(casts)
        hash = Contract.deploy(sk, unquote_splicing(quoted_args))

        tx = wait_tx(hash) |> IO.inspect(label: "Deployment Transaction")

        contract_address =
          get_contract_address(tx)
          |> IO.inspect(label: "contract address")

        unquote_splicing(inspectors)
      end
    end
  end

  defp quote_do_run(quoted_args, casts, inspectors, default_beneficiary) do
    quote do
      def do_run([unquote_splicing(quoted_args)], sk) do
        unquote(default_beneficiary)

        unquote_splicing(casts)
        hash = Contract.deploy(sk, unquote_splicing(quoted_args))

        tx = wait_tx(hash) |> IO.inspect(label: "Deployment Transaction")

        contract_address =
          get_contract_address(tx)
          |> IO.inspect(label: "contract address")

        unquote_splicing(inspectors)
      end
    end
  end

  defp quote_do_run(_) do
    quote do
      def do_run([], sk) do
        hash = Contract.deploy(sk)

        tx = wait_tx(hash) |> IO.inspect(label: "Deployment Transaction")

        contract_address =
          get_contract_address(tx)
          |> IO.inspect(label: "contract address")
      end
    end
  end

  def quote_args_inspect(arg_type_list) do
    Enum.map(arg_type_list, &do_quote_args_inspect/1)
  end

  defp do_quote_args_inspect({arg, type}) do
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

  defp get_function_selector_type("uint8"), do: {:uint, 8}
  defp get_function_selector_type("uint256"), do: {:uint, 256}
  defp get_function_selector_type("bool"), do: :bool
  defp get_function_selector_type("bytes"), do: :bytes
  defp get_function_selector_type("string"), do: :string
  defp get_function_selector_type("address"), do: :address

  def quote_args_cast(arg_type_list) do
    arg_type_list
    |> Enum.map(fn
      {arg, "int" <> _} -> {arg, :to_integer}
      {arg, "uint" <> _} -> {arg, :to_integer}
      {arg, "bool" <> _} -> {arg, :to_atom}
      _ -> nil
    end)
    |> Enum.filter(fn tuple -> tuple != nil end)
    |> Enum.map(&do_quote_args_cast/1)
  end

  defp do_quote_args_cast({arg, caster}) do
    arg_name = arg |> to_snake_atom |> Macro.var(nil)

    quote do
      unquote(arg_name) = apply(String, unquote(caster), [unquote(arg_name)])
    end
  end

  def quote_default_beneficiary(args) do
    args
    |> Enum.any?(fn arg -> arg == "beneficiary" end)
    |> case do
      true ->
        quote do
          %{alice: %{addr: alice}} = ChainUtil.wallets()
          beneficiary = Keyword.get(binding(), :beneficiary, alice)
        end

      false ->
        nil
    end
  end

  defp get_doc(%{"inputs" => inputs}) do
    args = inputs |> Enum.map(&Map.get(&1, "name"))
    types = inputs |> Enum.map(&Map.get(&1, "type"))
    arg_type_list = Enum.zip(args, types)
    "This is auto generated deployer, supported args: #{inspect(arg_type_list)}"
  end

  defp get_doc(_), do: "This is auto generated deployer."

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
