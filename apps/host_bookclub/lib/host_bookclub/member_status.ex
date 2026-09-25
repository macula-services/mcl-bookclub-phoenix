defmodule HostBookclub.MemberStatus do
  # Status bit flags for the member aggregate, following the house
  # convention: one power of two per flag, manipulated through
  # :evoq_bit_flags. The unregistered flag is the member's soft-delete.
  # The module owns the flags AND their readable names -- @labels is the
  # flag map the two meet in, and to_string/1 renders a mask through
  # evoq's own conversion. The projections derive their status strings
  # from here, never from a literal of their own (the Demon 68 relapse,
  # refused by test).
  @moduledoc false

  @registered 1
  @unregistered 2

  @labels %{@registered => "active", @unregistered => "unregistered"}

  def registered, do: @registered
  def unregistered, do: @unregistered

  def labels, do: @labels

  def to_string(status), do: :evoq_bit_flags.to_string(status, @labels)
end
