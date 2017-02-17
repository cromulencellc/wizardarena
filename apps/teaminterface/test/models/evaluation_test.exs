defmodule Teaminterface.EvaluationTest do
  use Teaminterface.ModelCase

  alias Teaminterface.Evaluation

  @valid_attrs %{connect: 42, memory: 42, success: 42, time: 42, timeout: 42}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Evaluation.changeset(%Evaluation{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Evaluation.changeset(%Evaluation{}, @invalid_attrs)
    refute changeset.valid?
  end
end
