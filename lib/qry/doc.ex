defmodule Qry.Doc do
  @moduledoc false

  defmodule Scalar do
    @moduledoc false

    defstruct [:field, :args]
  end

  defmodule NonScalar do
    @moduledoc false

    defstruct [:field, :args, :docs]
  end

  def parse(%Scalar{} = scalar_doc), do: scalar_doc

  def parse(%NonScalar{} = map_or_list_doc), do: map_or_list_doc

  def parse(field) when is_atom(field), do: %Scalar{field: field, args: %{}}

  def parse({field, args}) when is_atom(field) and is_map(args) do
    %Scalar{field: field, args: args}
  end

  def parse({field, docs}) when is_list(docs), do: parse({field, %{}, docs})

  def parse({field, args, docs}) when is_atom(field) and is_map(args) and is_list(docs) do
    docs = Enum.map(docs, &parse/1)
    %NonScalar{field: field, args: args, docs: docs}
  end
end
