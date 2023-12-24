# Qry

Query your domain.

    [
      project: [
        :name,
        author: [
          :first_name,
          :last_name,
          links: [:name, :url]
        ]
      ]
    ]
    |> MyRepo.query()

    {
      :ok,
      %{
        project: %{
          name: "Qry",
          author: %{
            first_name: "Austin",
            last_name: "Schneider",
            links: [
              %{name: "GitHub", url: "https://github.com/austinthecoder"},
              %{name: "X", url: "https://twitter.com/austinthecoder"}
            ]
          }
        }
      }
    }

## Setup

    defmodule MyRepo do
      use Qry.Repo

      def fetch(field, args, context) do
        ...
      end

      def fetch(parent, field, args, context) do
        ...
      end
    end

The repo must define two functions: `fetch/3` and `fetch/4`.

`fetch/3` – Returns the field data.

`fetch/4` – If the parent is a list, returns the a map of the field data keyed by each parent item. Otherwise returns the field data.

## Basic Example

    defmodule Project do
      defstruct [:id, :name]
    end

    defmodule Repo do
      use Qry.Repo

      @project %Project{id: 1, name: "Qry"}

      def fetch(:project, _args, _context) do
        {:ok, @project}
      end
    end

    iex> MyRepo.query(project: [:name])
    {:ok, %{project: %{name: "Qry"}}}

Let's add an `:authors` association to `Project`:

    defmodule Person do
      defstruct [:id, :first_name, :last_name, :project_id]
    end

    defmodule Repo do
      ...
      @authors [
        %Person{id: 1, first_name: "Austin", last_name: "Schneider", project_id: 1},
        %Person{id: 2, first_name: "John", last_name: "Smith", project_id: 2},
        %Person{id: 3, first_name: "Sally", last_name: "Sue", project_id: 1}
      ]

      def fetch(%Project{} = project, :authors, _args, _context) do
        authors =
          @authors
          |> Enum.filter(fn author ->
            author.project_id == project.id
          end)

        {:ok, authors}
      end
    end

    iex> MyRepo.query(
      project: [
        :name,
        authors: [:first_name, :last_name]
      ]
    )
    {
      :ok,
      %{
        project: %{
          name: "Qry",
          authors: [
            %{first_name: "Austin", last_name: "Schneider"},
            %{first_name: "Sally", last_name: "Sue"}
          ]
        }
      }
    }

Now let's add a `:links` association to `Person`:

    defmodule Link do
      defstruct [:id, :name, :url, :person_id]
    end

    defmodule Repo do
      ...
      @links [
        %Link{
          id: 1,
          name: "GitHub",
          url: "https://github.com/austinthecoder",
          person_id: 1
        },
        %Link{
          id: 2,
          name: "X",
          url: "https://twitter.com/austinthecoder",
          person_id: 1
        },
        %Link{
          id: 3,
          name: "Example",
          url: "https://example.com/john",
          person_id: 2
        },
        %Link{
          id: 4,
          name: "Website",
          url: "https://example.com/sally",
          person_id: 3
        },
      ]

      def fetch([%Person{} | _] = people, :links, _args, _context) do
        links =
          people
          |> Enum.reduce(%{}, fn person, acc ->
            links = @links |> Enum.filter(fn link -> link.person_id == person.id end)
            Map.put(acc, person, links)
          end)

        {:ok, links}
      end
    end

    iex> MyRepo.query(
      project: [
        :name,
        authors: [
          :first_name,
          :last_name,
          links: [:name, :url]
        ]
      ]
    )
    {
      :ok,
      %{
        project: %{
          name: "Qry",
          authors: [
            %{
              first_name: "Austin",
              last_name: "Schneider",
              links: [
                %{name: "GitHub", url: "https://github.com/austinthecoder"},
                %{name: "X", url: "https://twitter.com/austinthecoder"}
              ]
            },
            %{
              first_name: "Sally",
              last_name: "Sue",
              links: [
                %{name: "Website", url: "https://example.com/sally"}
              ]
            }
          ]
        }
      }
    }

## Documents

A doc consists of a field (atom), args (map), and subdocs (list). A doc can be expressed as an atom, a two-element tuple, or a three-element tuple.

A atom can be used for a field with no args or subdocs:

    MyRepo.query(:project)

If there are args or subdocs, a two-element tuple is used:

    # args only
    MyRepo.query({:project, %{id: "p1"}})

    # subdocs only
    MyRepo.query({:project, [:name]})

If there are both args and subdocs, a three-element tuple is used:

    MyRepo.query({:project, %{id: "p1"}, [:name]})

Use a list for multiple docs:

    MyRepo.query([:project, {:users, [:name]}])

Note: For two-element tuples, Elixir affords us the keyword list syntax:

    MyRepo.query(project: [name], users: [:name])

## Arguments

A doc can contain args (see above). They are given to `fetch/3` as the second argument:

    MyRepo.query(project: %{foo: "bar"})

    def fetch(:project, args, _context) do
      # args are `%{foo: "bar"}`
      ...
    end

And are given to `fetch/4` as the third argument:

    MyRepo.query(project: [authors: %{foo: "bar"}])

    def fetch(%Project{}, :authors, args, _context) do
      # args are `%{foo: "bar"}`
      ...
    end

## Context

You can provide a context (map) as the second argument to `MyRepo.query/2`. It defaults to an empty map. It is given to `fetch/3` and `fetch/4` as the last argument.

    MyRepo.query(:project, %{user_id: 123})
    MyRepo.query(project: [:authors], %{user_id: 123})

    def fetch(:project, _args, context) do
      # context is `%{user_id: 123}`
      ...
    end

    def fetch(%Project{}, :authors, _args, context) do
      # context is `%{user_id: 123}`
      ...
    end
