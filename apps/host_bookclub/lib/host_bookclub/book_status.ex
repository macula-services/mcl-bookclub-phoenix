defmodule HostBookclub.BookStatus do
  # Status bit flags for the book aggregate, following the house
  # convention: one power of two per flag, manipulated through
  # :evoq_bit_flags. The module owns the flags AND their readable names --
  # @labels is the flag map the two meet in, and to_string/1 renders a
  # mask through evoq's own conversion. The projections derive their
  # status strings from here, never from a literal of their own (the
  # Demon 68 relapse, refused by test).
  @moduledoc false

  @on_shelf 1
  @retired 2

  @labels %{@on_shelf => "on_shelf", @retired => "retired"}

  def on_shelf, do: @on_shelf
  def retired, do: @retired

  def labels, do: @labels

  def to_string(status), do: :evoq_bit_flags.to_string(status, @labels)
end
