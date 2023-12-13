defmodule Qry.Doc do
  defmodule Scalar do
    defstruct [:field, :args]
  end

  defmodule MapOrList do
    defstruct [:field, :args, :docs]
  end

  def parse(%Scalar{} = scalar_doc), do: scalar_doc

  def parse(%MapOrList{} = map_or_list_doc), do: map_or_list_doc

  def parse(field) when is_atom(field), do: %Scalar{field: field, args: %{}}

  def parse({field, args}) when is_atom(field) and is_map(args) do
    %Scalar{field: field, args: args}
  end

  def parse({field, docs}) when is_list(docs), do: parse({field, %{}, docs})

  def parse({field, args, docs}) when is_atom(field) and is_map(args) and is_list(docs) do
    docs = Enum.map(docs, &parse/1)
    %MapOrList{field: field, args: args, docs: docs}
  end
end
