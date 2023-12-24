defmodule Qry.Repo do
  @moduledoc """
  Defines a repository.
  """

  defmacro __using__([]) do
    quote do
      alias Qry.Doc

      @doc """
      Evaluates documents, returning a map of results.

      ## Examples

          MyRepo.query(truck: [:make, :model])

          %{
            truck: %{
              make: "Honda",
              model: "Civic"
            }
          }

      """
      def query(docs, context \\ %{})

      def query([], _), do: {:ok, %{}}

      def query([doc | docs], context) do
        {:ok, result1} = doc |> Doc.parse() |> query(context)
        {:ok, result2} = query(docs, context)
        {:ok, Map.merge(result1, result2)}
      end

      def query(%Doc.NonScalar{field: field, args: args, docs: docs}, context) do
        {:ok, value} = fetch(field, args, context)
        {:ok, subresult} = query_for(value, docs, context)
        {:ok, %{field => subresult}}
      end

      def query(%Doc.Scalar{field: field, args: args}, context) do
        {:ok, value} = fetch(field, args, context)
        {:ok, %{field => value}}
      end

      def query(doc, context), do: doc |> Doc.parse() |> query(context)

      defp query_for(nil, _docs, _context), do: {:ok, nil}

      defp query_for(map, docs, context) when is_map(map) and is_list(docs) do
        result =
          docs
          |> Enum.reduce(%{}, fn doc, acc ->
            {:ok, result} = query_for(map, doc, context)
            Map.merge(acc, result)
          end)

        {:ok, result}
      end

      defp query_for(map, %Doc.Scalar{field: field, args: args}, context) when is_map(map) do
        value =
          if Map.has_key?(map, field) do
            Map.get(map, field)
          else
            {:ok, value} = fetch(map, field, args, context)
            value
          end

        {:ok, %{field => value}}
      end

      defp query_for(map, %Doc.NonScalar{field: field, args: args, docs: docs}, context)
           when is_map(map) do
        {:ok, value} = fetch(map, field, args, context)
        {:ok, subresult} = query_for(value, docs, context)
        {:ok, %{field => subresult}}
      end

      defp query_for([], _docs, _context), do: {:ok, []}

      defp query_for(list, docs, context) when is_list(list) and is_list(docs) do
        acc = Enum.map(list, fn _ -> %{} end)

        result =
          docs
          |> Enum.reduce(acc, fn doc, acc ->
            {:ok, subvalues} = query_for(list, doc, context)

            acc
            |> Enum.with_index()
            |> Enum.map(fn {value, index} ->
              subvalue = Enum.at(subvalues, index)
              Map.merge(value, subvalue)
            end)
          end)

        {:ok, result}
      end

      defp query_for(list, %Doc.Scalar{field: field, args: args}, context) when is_list(list) do
        result =
          if !Enum.empty?(list) and list |> Enum.at(0) |> Map.has_key?(field) do
            list |> Enum.map(fn value -> %{field => Map.get(value, field)} end)
          else
            # todo: test
            {:ok, subvalue_by_value} = fetch(list, field, args, context)
            list |> Enum.map(fn value -> %{field => subvalue_by_value[value]} end)
          end

        {:ok, result}
      end

      defp query_for(list, %Doc.NonScalar{field: field, args: args, docs: docs}, context)
           when is_list(list) do
        {:ok, subvalue_by_value} = fetch(list, field, args, context)

        result =
          list
          |> Enum.map(fn value ->
            subvalue = subvalue_by_value[value]
            {:ok, result} = query_for(subvalue, docs, context)
            %{field => result}
          end)

        {:ok, result}
      end
    end
  end
end
