defmodule Qry do
  alias Qry.Doc

  def query([]), do: %{}

  def query([doc | docs]), do: doc |> Doc.parse() |> query() |> Map.merge(query(docs))

  def query(%Doc.MapOrList{field: field, args: args, docs: docs}) do
    value = fetch(field, args)
    %{field => query_for(value, docs)}
  end

  def query(%Doc.Scalar{field: field, args: args}), do: %{field => fetch(field, args)}

  def query(unknown), do: unknown |> Doc.parse() |> query()

  ##########

  defp query_for(nil, _docs), do: nil

  defp query_for(map, docs) when is_map(map) and is_list(docs) do
    docs
    |> Enum.reduce(%{}, fn doc, acc ->
      Map.merge(acc, query_for(map, doc))
    end)
  end

  defp query_for(map, %Doc.Scalar{field: field, args: args}) when is_map(map) do
    value =
      if Map.has_key?(map, field),
        do: Map.get(map, field),
        else: fetch(map, field, args)

    %{field => value}
  end

  defp query_for(map, %Doc.MapOrList{field: field, args: args, docs: docs}) when is_map(map) do
    value = fetch(map, field, args)
    %{field => query_for(value, docs)}
  end

  ##########

  defp query_for([], _), do: []

  defp query_for(list, docs) when is_list(list) and is_list(docs) do
    acc = Enum.map(list, fn _ -> %{} end)

    docs
    |> Enum.reduce(acc, fn doc, acc ->
      subvalues = query_for(list, doc)

      acc
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        subvalue = Enum.at(subvalues, index)
        Map.merge(value, subvalue)
      end)
    end)
  end

  defp query_for(list, %Doc.Scalar{field: field, args: args}) when is_list(list) do
    if !Enum.empty?(list) and list |> Enum.at(0) |> Map.has_key?(field) do
      list |> Enum.map(fn value -> %{field => Map.get(value, field)} end)
    else
      # todo: test
      subvalue_by_value = fetch(list, field, args)
      list |> Enum.map(fn value -> %{field => subvalue_by_value[value]} end)
    end
  end

  defp query_for(list, %Doc.MapOrList{field: field, args: args, docs: docs}) when is_list(list) do
    subvalue_by_value = fetch(list, field, args)

    list
    |> Enum.map(fn value ->
      subvalue = subvalue_by_value[value]
      %{field => query_for(subvalue, docs)}
    end)
  end

  ##########

  defp repo, do: Application.get_env(:g, :repo)

  defp fetch(field, args), do: repo().fetch(field, args)

  defp fetch(parent, field, args), do: repo().fetch(parent, field, args)
end
