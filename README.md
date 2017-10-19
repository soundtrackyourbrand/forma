# forma
_verb. /ʃeɪp/_

to adjust; adapt

[![Build Status](https://travis-ci.org/soundtrackyourbrand/forma.svg?branch=master)](https://travis-ci.org/soundtrackyourbrand/forma)

Applies typespecs to JSON-like data.

This module can parse JSON-like data (such as maps with key strings)
into a more structured form by trying to map it to conform to a
module's typespec.

This can generally be useful when interfacing with external data
sources that provide you data as JSON or MessagePack, but that you
wish to transform into either proper structs or richer data types
without a native JSON representation (such as dates or sets) in
your application.

It is heavily inspired by Go's way of dealing with JSON data.


```elixir
defmodule User do
  defstruct [:id, :name, :age, :gender]

  @type t :: %__MODULE__{
    id: String.t,
    name: String.t,
    age: non_neg_integer(),
    gender: :male | :female | :other | :prefer_not_to_say
  }
end

Forma.parse(%{"id" => "1", "name" => "Fredrik", "age" => 30, "gender" => "male"}, User)
# => %User{id: "1", name: "Fredrik", age: 30, gender: :male}
```

Forma tries to figure out how to translate its input to a typespec. However, not all
types have natural representations in JSON, for example dates, or don't want to expose
their internals (opaque types).

If you're in control of the module defining the type, you can implement the `__forma__/2`
function to handle parsing input to your desired type

```elixir
defmodule App.Date do
  @opaque t :: Date

  # first argument is the type to be parsed in this module
  def __forma__(:t, input) do
    case Date.from_iso8601(input) do
      {:ok, date} -> date
      {:error, reason} -> raise reason
    end
  end
end
```

If you're not in control of the module, you can pass a parser along as an optional
argument,

```elixir
defmodule LogRow do
  defstruct [:log, :timestamp]

  type t :: %__MODULE__{
    log: String.t,
    timestamp: NaiveDateTime.t
  }
end

date = fn input ->
  case NaiveDateTime.from_iso8601(input) do
    {:ok, datetime} -> datetime
    {:error, err} -> raise err
  end
end
parsers = %{{NaiveDateTime, :t} => date}
Forma.parse(%{"log" => "An error occurred", "timestamp" => "2015-01-23 23:50:07"}, LogRow, parsers)
```

The number of arguments to the parser functions depends on if the type is parameterized
or not (`MapSet.t` vs `MapSet.t(integer)`).


## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `forma` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:forma, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/forma](https://hexdocs.pm/forma).

