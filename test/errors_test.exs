defmodule ErrorsTest do
  use ExUnit.Case

  test "the first error encountered is returned" do
    assert Test.Repo.query(:error) == {:error, "error1"}
    assert Test.Repo.query(session: [:error]) == {:error, "error2"}
  end
end
