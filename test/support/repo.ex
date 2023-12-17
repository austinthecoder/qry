defmodule Test.Repo do
  use Qry.Repo

  defmodule Session do
    defstruct [:id, :user_id]
  end

  defmodule Org do
    defstruct [:id, :name]
  end

  defmodule User do
    defstruct [:id]
  end

  defmodule Login do
    defstruct [:duration]
  end

  defmodule Location do
    defstruct [:state]
  end

  defmodule Part do
    defstruct [:id, :serial]
  end

  ##########
  # fetch(field, args)

  def fetch(:app, %{active: true}, %{}), do: "Qry"

  def fetch(:app, %{}, %{user_id: "u1"}), do: "Qry with context"

  def fetch(:app, %{}, %{}), do: "Qry"

  def fetch(:session, %{no_user: true}, %{}), do: sessions() |> Enum.find(&(!&1.user_id))

  def fetch(:session, %{id: "s3"}, %{}), do: sessions() |> Enum.find(&(&1.id == "s3"))

  def fetch(:session, %{}, %{}), do: sessions() |> Enum.at(0)

  def fetch(:orgs, %{name: name}, %{}), do: orgs() |> Enum.filter(&(&1.name == name))

  def fetch(:orgs, %{}, %{}), do: orgs()

  ##########
  # fetch(parent, field, args)

  def fetch(%Session{id: "s1"}, :clicks, %{}, %{}), do: 7

  def fetch(%Session{id: "s1"}, :google_user_id, %{arg: "x"}, %{}), do: "gu1"

  def fetch(%Session{id: "s1"} = session, :user, %{logged_in: true}, %{}) do
    %User{id: session.user_id}
  end

  def fetch(%Session{id: "s1"}, :browser, %{}, %{}), do: nil

  def fetch(%Session{id: "s1"} = session, :user, %{}, %{user_id: "u1"}) do
    %User{id: "#{session.user_id} with context"}
  end

  def fetch(%Session{id: "s1"} = session, :user, %{}, %{}), do: %User{id: session.user_id}

  def fetch(%Session{id: "s1"}, :logins, %{}, %{}),
    do: [%Login{duration: 10}, %Login{duration: 20}]

  def fetch([%Org{id: "o1"} = w1, %Org{id: "o2"} = w2], :parts, %{serial: "2"}, %{}) do
    %{w1 => [%Part{id: "p2", serial: "2"}], w2 => []}
  end

  def fetch([%Org{id: "o1"} = w1, %Org{id: "o2"} = w2], :location, %{}, %{}) do
    %{w1 => %Location{state: "GA"}, w2 => %Location{state: "IL"}}
  end

  def fetch([%Org{id: "o1"} = w1, %Org{id: "o2"} = w2], :buildings, %{}, %{}) do
    %{w1 => [], w2 => []}
  end

  def fetch([%Org{id: "o1"} = w1, %Org{id: "o2"} = w2], :parts, %{}, %{}) do
    %{
      w1 => [%Part{id: "p1", serial: "1"}, %Part{id: "p2", serial: "2"}],
      w2 => [%Part{id: "p3", serial: "3"}]
    }
  end

  ##########

  defp sessions do
    [
      %Session{id: "s1", user_id: 2},
      %Session{id: "s2", user_id: nil}
    ]
  end

  defp orgs do
    [
      %Org{id: "o1", name: "Org1"},
      %Org{id: "o2", name: "Org2"}
    ]
  end
end
