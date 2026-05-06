defmodule Parking.Ecto.JsonList do
  @moduledoc "Ecto type for JSON arrays stored as jsonb in PostgreSQL."
  use Ecto.Type

  def type, do: :map

  def cast(value) when is_list(value), do: {:ok, value}
  def cast(value) when is_map(value), do: {:ok, value}
  def cast(_), do: :error

  def load(value), do: {:ok, value}

  def dump(value) when is_list(value), do: {:ok, value}
  def dump(value) when is_map(value), do: {:ok, value}
  def dump(_), do: :error

  def equal?(a, b), do: a == b
  def embed_as(_), do: :self
end
