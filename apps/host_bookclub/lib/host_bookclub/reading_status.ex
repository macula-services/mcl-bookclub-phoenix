defmodule HostBookclub.ReadingStatus do
  # Status bit flags for the reading aggregate, following the house
  # convention: one power of two per flag, manipulated through
  # :evoq_bit_flags. The module owns the flags AND their readable names --
  # @labels is the flag map the two meet in, and to_string/1 renders a
  # mask through evoq's own conversion. The projections derive their
  # status strings from here, never from a literal of their own (the
  # Demon 68 relapse, refused by test).
  @moduledoc false

  @in_progress 1
  @finished 2

  @labels %{@in_progress => "in_progress", @finished => "finished"}

  def in_progress, do: @in_progress
  def finished, do: @finished

  def labels, do: @labels

  def to_string(status), do: :evoq_bit_flags.to_string(status, @labels)
end
