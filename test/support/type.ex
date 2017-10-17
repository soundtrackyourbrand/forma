defmodule Forma.Date do
  @opaque t :: NaiveDateTime

  def __forma__(:t, input) do
    case NaiveDateTime.from_iso8601(input) do
      {:ok, datetime} -> datetime
      {:error, err} -> raise err
    end
  end
end

defmodule Forma.Type do
  defstruct [:string, :list, :map, :strict, :float, :int, :neg_int,
             :non_neg_int, :pos_int, :range, :atom, :union, :bool,
             :recursive, :date, :set, :datetime]

  @type t :: %__MODULE__{
    string: String.t,
    list: [integer()],
    map: %{
      optional(atom) => String.t,
    },
    strict: %{
      foo: integer()
    },

    float: float(),
    int: integer(),
    neg_int: neg_integer(),
    non_neg_int: non_neg_integer(),
    pos_int: pos_integer(),
    range: 1..10,

    atom: atom,
    union: union,
    bool: boolean,
    recursive: t,
    date: Forma.Date.t,
    datetime: DateTime.t,
    set: MapSet.t(integer)
  }

  @type union :: :foo | :bar
end
