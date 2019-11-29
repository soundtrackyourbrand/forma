defmodule FormaTest do
  use ExUnit.Case
  doctest Forma

  setup do
    {:module, _} = Code.ensure_compiled(Forma.Date)
    {:module, _} = Code.ensure_compiled(Forma.Type)
    :ok
  end

  test "it parses map with required key" do
    {:ok, res} = Forma.parse(%{"required" => %{"key" => "value"}}, Forma.Type)
    assert res.required["key"] == "value"
  end

  test "it parses strings" do
    {:ok, res} = Forma.parse(%{"string" => "a string"}, Forma.Type)
    assert res.string == "a string"
  end

  test "it parses lists" do
    {:ok, res} = Forma.parse(%{"list" => [1, 1.2]}, Forma.Type)
    assert res.list == [1, 1]
  end

  test "it parses maps" do
    {:ok, res} = Forma.parse(%{"map" => %{"foo" => "bar"}}, Forma.Type)
    assert res.map == %{foo: "bar"}
  end

  test "it parses strict maps" do
    {:ok, res} = Forma.parse(%{"strict" => %{"foo" => 1}}, Forma.Type)
    assert res.strict == %{foo: 1}
  end

  test "it disregards nil keys in strict maps" do
    {:ok, res} = Forma.parse(%{"strict" => %{"foo" => 1, "bar" => "baz"}}, Forma.Type)
    assert res.strict == %{foo: 1}
  end

  test "it parses floats" do
    {:ok, res} = Forma.parse(%{"float" => 1.1}, Forma.Type)
    assert res.float == 1.1
  end

  test "it parses ints" do
    {:ok, res} = Forma.parse(%{
          "int" => -1,
          "neg_int" => -1,
          "non_neg_int" => 0,
          "pos_int" => 1,
    }, Forma.Type)

    assert res.int == -1
    assert res.neg_int == -1
    assert res.non_neg_int == 0
    assert res.pos_int == 1
  end

  test "it parses ranges" do
    {:ok, res} = Forma.parse(%{"range" => 3}, Forma.Type)

    assert res.range == 3
  end

  test "it parses atoms" do
    {:ok, res} = Forma.parse(%{"atom" => "hi"}, Forma.Type)

    assert res.atom == :hi
  end

  test "it parses unions" do
    {:ok, res} = Forma.parse(%{"union" => "bar"}, Forma.Type)

    assert res.union == :bar
  end

  test "it parses bools" do
    {:ok, res} = Forma.parse(%{"bool" => true}, Forma.Type)

    assert res.bool == true
  end

  test "it parses recursively" do
    {:ok, res} = Forma.parse(%{"recursive" => %{"string" => "hi"}}, Forma.Type)

    assert res.recursive == %Forma.Type{string: "hi"}
  end

  test "it parses dates" do
    {:ok, res} = Forma.parse(%{"date" => "2015-01-23 23:50:07"}, Forma.Type)

    assert res.date == ~N[2015-01-23 23:50:07]
  end

  test "it parses builtin types" do
    dt = fn input ->
      case DateTime.from_iso8601(input) do
        {:ok, t, _} -> t
        {:error, err} -> raise err
      end
    end

    {:ok, res} = Forma.parse(%{"datetime" => "2015-01-23T23:50:07Z"}, Forma.Type,
      %{{DateTime, :t} => dt})

    expected = res.datetime
    assert {:ok, ^expected, _} = DateTime.from_iso8601("2015-01-23T23:50:07Z")
  end

  test "it parses sets" do
    {:ok, res} = Forma.parse(%{"set" => [1, 1, 2, 3]}, Forma.Type,
      %{{MapSet, :t} => fn input, _ -> MapSet.new(input) end})

    assert res.set == MapSet.new([1, 2, 3])
  end

  test "it parses \"\" as nil" do
    {:ok, res} = Forma.parse("", {Forma.Type, :union})
    assert res == nil
  end

  test "it parses nil as nil" do
    {:ok, res} = Forma.parse(nil, {Forma.Type, :union})
    assert res == nil
  end
end
