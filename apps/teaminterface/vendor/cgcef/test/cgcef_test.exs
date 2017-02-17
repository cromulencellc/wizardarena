defmodule CgcefTest do
  use ExUnit.Case
  doctest Cgcef

  test "CGC CB" do
    fixture "LUNGE_00001.cgc", fn(f) ->
      assert Cgcef.verify(f) == :ok
    end
  end

  test "ELF CB" do
    fixture "LUNGE_00001.elf", fn(f) ->
      assert Cgcef.verify(f) ==
        {:error, "did not identify as a DECREE binary (ident ELF)"}
    end
  end

  test "CGC PoV" do
    fixture "pov_0.pov.cgc", fn(f) ->
      assert Cgcef.verify(f) == :ok
    end
  end

  test "ELF PoV" do
    fixture "pov_0.pov.elf", fn(f) ->
      assert Cgcef.verify(f) ==
        {:error, "did not identify as a DECREE binary (ident ELF)"}
    end
  end

  test "overlapping CB" do
    fixture "overlap.cgc", fn(f) ->
      assert Cgcef.verify(f) ==
        {:error, "Program header #1 collides with flag page"}
    end
  end

  test "unrecognized segment CB" do
    fixture "mystery_segment.cgc", fn(f) ->
      assert Cgcef.verify(f) ==
        {:error, "Invalid program header #0 2h."}
    end
  end

  test "weirdly-offset program header CB" do
    fixture "weird-offset.cgc", fn(f) ->
      assert Cgcef.verify(f) == :ok
    end
  end

  def fixture(filename, closure) do
    __DIR__
    |> Path.join("fixtures")
    |> Path.join(filename)
    |> File.open([:read], closure)
  end
end
