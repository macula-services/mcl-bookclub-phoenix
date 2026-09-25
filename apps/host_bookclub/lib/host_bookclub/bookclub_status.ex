defmodule HostBookclub.BookclubStatus do
  # Status bit flags for the bookclub aggregate, the house convention:
  # one power of two per flag, manipulated through :evoq_bit_flags. The
  # module owns the flags AND their readable names -- @labels is the flag
  # map the two meet in, and to_string/1 renders a mask through evoq's own
  # conversion (evoq_bit_flags:to_string/2). The projections derive their
  # status strings from here, never from a literal of their own (the
  # Demon 68 relapse, refused by test).
  @moduledoc false

  @initiated 1
  @archived 2

  @labels %{@initiated => "active", @archived => "archived"}

  def initiated, do: @initiated
  def archived, do: @archived

  def labels, do: @labels

  def to_string(status), do: :evoq_bit_flags.to_string(status, @labels)
end
