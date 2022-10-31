defmodule ChainUtil.ContractGen do
  use ChainUtil.AutoGen.Util
  require UtilityBelt.CodeGen.DynamicModule
  alias UtilityBelt.CodeGen.DynamicModule

  def gen_contract(
        contract_json_path,
        module_name,
        opts \\ []
      ) do
    output_folder = Keyword.get(opts, :output_folder, "priv/gen")
    create_beam = Keyword.get(opts, :create_beam, false)

    file_name = Path.basename(contract_json_path, ".json")
    contract_json = read_contract_json(contract_json_path)
    bytecode_file_path = copy_bytecode(output_folder, file_name, contract_json["bytecode"])

    quoted_preamble = quote_preamble(bytecode_file_path)

    link_references = get_link_references(contract_json)

    constructor = get_constructor(contract_json)

    functions = get_functions(contract_json)

    contents = [
      quote_constructor(constructor, link_references)
      | Enum.map(functions, &quote_function_call/1)
    ]

    DynamicModule.gen(
      module_name,
      quoted_preamble,
      contents,
      doc: "This is an auto generated wrapper module.",
      path: Path.join(File.cwd!(), output_folder),
      create: create_beam
    )
  end

  def quote_preamble(bytecode_file_path) do
    quote do
      @contract_bytecode File.read!(unquote(bytecode_file_path))

      def ensure_no_hex("0x" <> hex), do: Base.decode16!(hex, case: :mixed)
      def ensure_no_hex(var), do: var
    end
  end

  def quote_constructor(constructor, link_references) do
    quoted_deployment_args = quote_deployment_args(constructor, link_references)
    quoted_constructor_args_list = quote_constructor_args_list(constructor)
    quoted_constructor_sig = quote_constructor_sig(constructor)
    quoted_link_references = quote_link_references(link_references)

    quote do
      def deploy(unquote_splicing(quoted_deployment_args)) do
        unquote(quoted_constructor_args_list)

        input = @contract_bytecode <> unquote(quoted_constructor_sig)

        unquote_splicing(quoted_link_references)

        k = Keyword.get(binding(), :private_key)
        OcapRpc.Eth.Transaction.send_transaction(k, nil, 0, input: input, gas_limit: 6_000_000)
      end
    end
  end

  defp quote_deployment_args(constructor, link_references) do
    constructor_args =
      case constructor do
        nil ->
          []

        %{"inputs" => inputs} ->
          inputs |> Enum.map(&Map.get(&1, "name")) |> Enum.map(&to_snake_atom/1)
      end

    link_reference_args =
      link_references
      |> Enum.map(&elem(&1, 0))

    [:private_key | constructor_args ++ link_reference_args] |> Enum.map(&Macro.var(&1, nil))
  end

  defp quote_constructor_args_list(nil) do
    quote do
    end
  end

  defp quote_constructor_args_list(%{"inputs" => inputs}) do
    args = inputs |> Enum.map(&Map.get(&1, "name")) |> Enum.map(&to_snake_atom/1)

    quote do
      values =
        unquote(args)
        |> Enum.map(fn k -> Keyword.get(binding(), k) end)
        |> Enum.map(&ensure_no_hex/1)
    end
  end

  defp quote_constructor_sig(nil), do: ""

  defp quote_constructor_sig(%{"inputs" => inputs}) do
    types = inputs |> Enum.map(&Map.get(&1, "type")) |> Enum.join(",")
    func_sig = "(#{types})"

    quote do
      unquote(func_sig)
      |> ABI.encode([List.to_tuple(values)])
      |> Base.encode16(case: :lower)
    end
  end

  defp quote_link_references(link_references) do
    link_references
    |> Enum.map(fn {lib_name, hash} ->
      quote do
        input = String.replace(input, unquote(hash), unquote(Macro.var(lib_name, nil)))
      end
    end)
  end

  @doc """
  An `abi` looks like this:
    {
      "inputs": [
        {
          "internalType": "address",
          "name": "owner",
          "type": "address"
        },
        {
          "internalType": "address",
          "name": "operator",
          "type": "address"
        }
      ],
      "name": "isApprovedForAll",
      "outputs": [
        {
          "internalType": "bool",
          "name": "",
          "type": "bool"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  """
  def quote_function_call(abi) do
    func_name = to_snake_atom(abi["name"])
    args = abi["inputs"] |> Enum.map(&Map.get(&1, "name")) |> Enum.map(&to_snake_atom/1)
    types = abi["inputs"] |> Enum.map(&Map.get(&1, "type")) |> Enum.join(",")
    func_sig = "#{abi["name"]}(#{types})"

    quote_function_call(abi["stateMutability"], func_name, args, func_sig)
  end

  # def is_approved_for_all(contract, owner, operator) do
  #   values = Enum.map([:owner, :operator], fn k -> Keyword.get(binding(), k) end)
  #   input = ABI.encode("isApprovedForAll(address,address)", values)
  #   c = Keyword.get(binding(), :contract)
  #   message = %{to: c, data: input}
  #   OcapRpc.Eth.Chain.call(message)
  # end
  defp quote_function_call(state_mutability, func_name, args, func_sig)
       when state_mutability in ["view", "pure"] do
    quoted_args = [:contract | args] |> Enum.map(&Macro.var(&1, nil))

    quote do
      def unquote(func_name)(unquote_splicing(quoted_args)) do
        values =
          unquote(args)
          |> Enum.map(fn k -> Keyword.get(binding(), k) end)
          |> Enum.map(&ensure_no_hex/1)

        input = unquote(func_sig) |> ABI.encode(values) |> Base.encode16(case: :lower)
        c = Keyword.get(binding(), :contract)
        message = %{to: c, data: input}
        OcapRpc.Eth.Chain.call(message, :latest)
      end
    end
  end

  defp quote_function_call("nonpayable", func_name, args, func_sig) do
    quoted_args = [:contract, :private_key | args] |> Enum.map(&Macro.var(&1, nil))

    quote do
      def unquote(func_name)(unquote_splicing(quoted_args)) do
        values =
          unquote(args)
          |> Enum.map(fn k -> Keyword.get(binding(), k) end)
          |> Enum.map(&ensure_no_hex/1)

        input = unquote(func_sig) |> ABI.encode(values) |> Base.encode16(case: :lower)
        c = Keyword.get(binding(), :contract)
        k = Keyword.get(binding(), :private_key)
        OcapRpc.Eth.Transaction.send_transaction(k, c, 0, input: input)
      end
    end
  end

  defp quote_function_call("payable", func_name, args, func_sig) do
    quoted_args = [:contract, :private_key, :wei | args] |> Enum.map(&Macro.var(&1, nil))

    quote do
      def unquote(func_name)(unquote_splicing(quoted_args)) do
        values =
          unquote(args)
          |> Enum.map(fn k -> Keyword.get(binding(), k) end)
          |> Enum.map(&ensure_no_hex/1)

        input = unquote(func_sig) |> ABI.encode(values) |> Base.encode16(case: :lower)
        c = Keyword.get(binding(), :contract)
        k = Keyword.get(binding(), :private_key)
        w = Keyword.get(binding(), :wei)
        OcapRpc.Eth.Transaction.send_transaction(k, c, w, input: input)
      end
    end
  end

  defp copy_bytecode(output_folder, file_name, bytecode) do
    folder_path = Path.join(File.cwd!(), output_folder)

    if File.exists?(folder_path) == false do
      File.mkdir_p!(folder_path)
    end

    bytecode_file_path = Path.join(folder_path, file_name)
    File.write!(bytecode_file_path, bytecode)

    bytecode_file_path
  end
end
