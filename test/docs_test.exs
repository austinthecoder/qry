defmodule DocsTest do
  use ExUnit.Case

  defmodule Project do
    defstruct [:id, :name]
  end

  defmodule Person do
    defstruct [:id, :first_name, :last_name, :project_id]
  end

  defmodule Link do
    defstruct [:id, :name, :url, :person_id]
  end

  defmodule Repo do
    use Qry.Repo

    @project %Project{id: 1, name: "Qry"}

    @authors [
      %Person{id: 1, first_name: "Austin", last_name: "Schneider", project_id: 1},
      %Person{id: 2, first_name: "John", last_name: "Smith", project_id: 2},
      %Person{id: 3, first_name: "Sally", last_name: "Sue", project_id: 1}
    ]

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
      }
    ]

    def fetch(:project, _args, _context) do
      {:ok, @project}
    end

    def fetch(%Project{} = project, :authors, _args, _context) do
      authors =
        @authors
        |> Enum.filter(fn author ->
          author.project_id == project.id
        end)

      {:ok, authors}
    end

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

  test "examples in docs work" do
    assert Repo.query(project: [:name]) == {:ok, %{project: %{name: "Qry"}}}

    assert Repo.query(
             project: [
               :name,
               authors: [:first_name, :last_name]
             ]
           ) ==
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

    assert Repo.query(
             project: [
               :name,
               authors: [
                 :first_name,
                 :last_name,
                 links: [:name, :url]
               ]
             ]
           ) ==
             {:ok,
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
              }}
  end
end
