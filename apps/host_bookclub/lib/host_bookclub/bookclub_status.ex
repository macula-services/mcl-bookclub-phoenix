defmodule HostBookclub.BookclubStatus do
  # Status bit flags for the bookclub aggregate, the house convention:
  # one power of two per flag, manipulated through :evoq_bit_flags. The
  # readable status strings are computed at projection time, never at
  # query time.
  @moduledoc false

  def initiated, do: 1
  def archived, do: 2
end
