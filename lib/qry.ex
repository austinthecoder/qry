defmodule Qry do
  @moduledoc """
  The main interface for querying.
  """

  alias Qry.Doc

  @doc """
  Evaluates documents, returning a map of results.

  ## Examples

      Qry.query(truck: [:make, :model])

      %{
        truck: %{
          make: "Honda",
          model: "Civic"
        }
      }

  """
  def query(docs, context \\ %{})

  def query([], _), do: %{}

  def query([doc | docs], context),
    do: doc |> Doc.parse() |> query(context) |> Map.merge(query(docs, context))

  def query(%Doc.NonScalar{field: field, args: args, docs: docs}, context) do
    value = fetch(field, args, context)
    %{field => query_for(value, docs, context)}
  end

  def query(%Doc.Scalar{field: field, args: args}, context) do
    %{field => fetch(field, args, context)}
  end

  def query(doc, context), do: doc |> Doc.parse() |> query(context)

  ##########

  defp query_for(nil, _docs, _context), do: nil

  defp query_for(map, docs, context) when is_map(map) and is_list(docs) do
    docs
    |> Enum.reduce(%{}, fn doc, acc ->
      Map.merge(acc, query_for(map, doc, context))
    end)
  end

  defp query_for(map, %Doc.Scalar{field: field, args: args}, context) when is_map(map) do
    value =
      if Map.has_key?(map, field),
        do: Map.get(map, field),
        else: fetch(map, field, args, context)

    %{field => value}
  end

  defp query_for(map, %Doc.NonScalar{field: field, args: args, docs: docs}, context)
       when is_map(map) do
    value = fetch(map, field, args, context)
    %{field => query_for(value, docs, context)}
  end

  ##########

  defp query_for([], _docs, _context), do: []

  defp query_for(list, docs, context) when is_list(list) and is_list(docs) do
    acc = Enum.map(list, fn _ -> %{} end)

    docs
    |> Enum.reduce(acc, fn doc, acc ->
      subvalues = query_for(list, doc, context)

      acc
      |> Enum.with_index()
      |> Enum.map(fn {value, index} ->
        subvalue = Enum.at(subvalues, index)
        Map.merge(value, subvalue)
      end)
    end)
  end

  defp query_for(list, %Doc.Scalar{field: field, args: args}, context) when is_list(list) do
    if !Enum.empty?(list) and list |> Enum.at(0) |> Map.has_key?(field) do
      list |> Enum.map(fn value -> %{field => Map.get(value, field)} end)
    else
      # todo: test
      subvalue_by_value = fetch(list, field, args, context)
      list |> Enum.map(fn value -> %{field => subvalue_by_value[value]} end)
    end
  end

  defp query_for(list, %Doc.NonScalar{field: field, args: args, docs: docs}, context)
       when is_list(list) do
    subvalue_by_value = fetch(list, field, args, context)

    list
    |> Enum.map(fn value ->
      subvalue = subvalue_by_value[value]
      %{field => query_for(subvalue, docs, context)}
    end)
  end

  ##########

  defp repo, do: Application.get_env(:g, :repo)

  defp fetch(field, args, context), do: repo().fetch(field, args, context)

  defp fetch(parent, field, args, context), do: repo().fetch(parent, field, args, context)
end
