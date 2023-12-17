defmodule QryTest do
  use ExUnit.Case

  test "can query nothing" do
    assert Test.Repo.query([]) == %{}
  end

  test "can query top-level scalars" do
    assert Test.Repo.query([:app]) == %{app: "Qry"}
  end

  test "can query top-level maps" do
    assert Test.Repo.query(session: [:id]) == %{session: %{id: "s1"}}
  end

  test "can query top-level lists" do
    assert Test.Repo.query(orgs: [:name]) == %{orgs: [%{name: "Org1"}, %{name: "Org2"}]}
  end

  test "can query multiple top-level fields" do
    assert [:app, session: [:id], orgs: [:name]] |> Test.Repo.query() == %{
             app: "Qry",
             session: %{id: "s1"},
             orgs: [%{name: "Org1"}, %{name: "Org2"}]
           }
  end

  test "nil map field stops evaluating subdocs" do
    assert Test.Repo.query(session: [browser: [:name]]) == %{session: %{browser: nil}}
  end

  test "empty list field stops evaluating subdocs" do
    assert Test.Repo.query(orgs: [buildings: [:address]]) == %{
             orgs: [%{buildings: []}, %{buildings: []}]
           }
  end

  test "can query maps under maps" do
    assert Test.Repo.query(session: [user: [:id]]) == %{session: %{user: %{id: 2}}}
  end

  test "can query lists under maps" do
    assert Test.Repo.query(session: [logins: [:duration]]) == %{
             session: %{logins: [%{duration: 10}, %{duration: 20}]}
           }
  end

  test "can query maps under lists" do
    assert Test.Repo.query(orgs: [location: [:state]]) == %{
             orgs: [%{location: %{state: "GA"}}, %{location: %{state: "IL"}}]
           }
  end

  test "can query lists under lists" do
    assert Test.Repo.query(orgs: [parts: [:serial]]) == %{
             orgs: [
               %{parts: [%{serial: "1"}, %{serial: "2"}]},
               %{parts: [%{serial: "3"}]}
             ]
           }
  end

  test "can query scalars not part of parent map/list" do
    assert Test.Repo.query(session: [:clicks]) == %{session: %{clicks: 7}}
  end

  test "can pass args to top-level scalar" do
    assert Test.Repo.query({:app, %{active: true}}) == %{app: "Qry"}
  end

  test "can pass args to top-level map" do
    assert Test.Repo.query({:session, %{no_user: true}, [:id]}) == %{session: %{id: "s2"}}
  end

  test "can pass args to top-level list" do
    assert Test.Repo.query({:orgs, %{name: "Org2"}, [:name]}) == %{orgs: [%{name: "Org2"}]}
  end

  test "can pass args to nested scalar" do
    assert Test.Repo.query(session: [{:google_user_id, %{arg: "x"}}]) == %{
             session: %{google_user_id: "gu1"}
           }
  end

  test "can pass args to nested map" do
    assert Test.Repo.query(session: [{:user, %{logged_in: true}, [:id]}]) == %{
             session: %{user: %{id: 2}}
           }
  end

  test "can pass args to nested list" do
    assert Test.Repo.query(orgs: [{:parts, %{serial: "2"}, [:id]}]) == %{
             orgs: [%{parts: [%{id: "p2"}]}, %{parts: []}]
           }
  end

  test "can pass args for multiple fields" do
    assert [
             {:app, %{active: true}},
             {:session, %{id: "s3"}, [:id]},
             {:orgs, %{name: "Org2"}, [:name]}
           ]
           |> Test.Repo.query() == %{app: "Qry", orgs: [%{name: "Org2"}], session: nil}
  end

  test "can pass context" do
    assert Test.Repo.query(:app, %{user_id: "u1"}) == %{app: "Qry with context"}

    assert Test.Repo.query([session: [user: [:id]]], %{user_id: "u1"}) == %{
             session: %{user: %{id: "2 with context"}}
           }
  end
end
