defmodule Qry.Repo do
  @moduledoc """
  Defines a repository.
  """

  defmacro __using__([]) do
    quote location: :keep do
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

      @spec query(Doc.parsable_doc() | list(Doc.parsable_doc())) ::
              {:ok, map()} | {:error | any()}

      def query(docs, context \\ %{})

      def query([], _), do: {:ok, %{}}

      def query([doc | docs], context) do
        with {:ok, result1} <- doc |> Doc.parse() |> query(context),
             {:ok, result2} = query(docs, context) do
          {:ok, Map.merge(result1, result2)}
        else
          {:error, _} = result ->
            result
        end
      end

      def query(%Doc.NonScalar{field: field, args: args, docs: docs}, context) do
        with {:ok, value} <- fetch(field, args, context),
             {:ok, subresult} <- query_for(value, docs, context) do
          {:ok, %{field => subresult}}
        else
          {:error, _} = result ->
            result
        end
      end

      def query(%Doc.Scalar{field: field, args: args}, context) do
        case fetch(field, args, context) do
          {:ok, value} -> {:ok, %{field => value}}
          {:error, _} = result -> result
        end
      end

      def query(doc, context), do: doc |> Doc.parse() |> query(context)

      @spec query_for(
              nil | map() | list(),
              Doc.doc() | list(Doc.doc()),
              map()
            ) :: {:ok, map() | list()} | {:error, any()}

      defp query_for(nil, _docs, _context), do: {:ok, nil}

      defp query_for(map, [], context) when is_map(map), do: {:ok, %{}}

      defp query_for(map, [doc | docs], context) when is_map(map) do
        with {:ok, result1} <- query_for(map, doc, context),
             {:ok, result2} = query_for(map, docs, context) do
          {:ok, Map.merge(result1, result2)}
        else
          {:error, _} = result -> result
        end
      end

      defp query_for(map, %Doc.Scalar{field: field, args: args}, context) when is_map(map) do
        if Map.has_key?(map, field) do
          value = Map.get(map, field)
          {:ok, %{field => value}}
        else
          case fetch(map, field, args, context) do
            {:ok, value} -> {:ok, %{field => value}}
            {:error, _} = result -> result
          end
        end
      end

      defp query_for(map, %Doc.NonScalar{field: field, args: args, docs: docs}, context)
           when is_map(map) do
        with {:ok, value} <- fetch(map, field, args, context),
             {:ok, subresult} <- query_for(value, docs, context) do
          {:ok, %{field => subresult}}
        else
          {:error, _} = result -> result
        end
      end

      defp query_for([], _docs, _context), do: {:ok, []}

      defp query_for(list, [], _context) when is_list(list) do
        {:ok, list |> Enum.map(fn _ -> %{} end)}
      end

      defp query_for(list, [doc | docs], context) when is_list(list) do
        with {:ok, list1} <- query_for(list, doc, context),
             {:ok, list2} <- query_for(list, docs, context) do
          result =
            [list1, list2]
            |> List.zip()
            |> Enum.map(fn {r1, r2} -> Map.merge(r1, r2) end)

          {:ok, result}
        else
          {:error, _} = result -> result
        end
      end

      defp query_for(list, %Doc.Scalar{field: field, args: args}, context) when is_list(list) do
        if !Enum.empty?(list) and list |> Enum.at(0) |> Map.has_key?(field) do
          result = list |> Enum.map(fn value -> %{field => Map.get(value, field)} end)
          {:ok, result}
        else
          # todo: test
          case fetch(list, field, args, context) do
            {:ok, subvalue_by_value} ->
              result = list |> Enum.map(fn value -> %{field => subvalue_by_value[value]} end)
              {:ok, result}

            {:error, _} = result ->
              result
          end
        end
      end

      defp query_for(list, %Doc.NonScalar{field: field, args: args, docs: docs}, context)
           when is_list(list) do
        case fetch(list, field, args, context) do
          {:ok, subvalue_by_value} ->
            list
            |> Enum.reduce_while({:ok, []}, fn value, acc ->
              result = subvalue_by_value |> Map.get(value) |> query_for(docs, context)

              case result do
                {:ok, result} ->
                  {:ok, results} = acc
                  {:cont, {:ok, results ++ [%{field => result}]}}

                {:error, _} = result ->
                  {:halt, result}
              end
            end)

          {:error, _} = result ->
            result
        end
      end
    end
  end
end
