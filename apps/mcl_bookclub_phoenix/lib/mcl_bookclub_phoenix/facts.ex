defmodule MclBookclubPhoenix.Facts do
  # mcl-bookclub's public contract on the mesh: three facts.
  #
  #   member_registered_v1 on `<realm>/mcl-bookclub/bookclub/member/member_registered_v1'
  #   book_procured_v1    on `<realm>/mcl-bookclub/bookclub/book/book_procured_v1'
  #   book_retired_v1     on `<realm>/mcl-bookclub/bookclub/book/book_retired_v1'
  #
  # One topic per fact kind; the ids and names are in the payload, not the
  # topic name: a consumer subscribes once and filters. Every fact carries
  # club_id AND club_name -- the club is a payload parameter, never a
  # namespace, which is what lets one topic set serve a thousand clubs.
  #
  # The domain event stays internal; what leaves is a FACT on the mesh,
  # and this module is the only place the two shapes meet (the emitter
  # desks translate, nobody else). Text travels as CBOR text, booleans as
  # 1/0.
  #
  # This module and the emit_* desks are the ONLY facade modules that name
  # the mesh SDK; the division apps never do.
  @moduledoc false

  @org "mcl-bookclub"
  @domain "bookclub"
  @version 1

  @member_fields [:member_id, :club_id, :club_name, :name, :registered_at]
  @book_fields [:book_id, :club_id, :club_name, :title, :author, :procured_at]
  @retired_fields [
    :book_id,
    :club_id,
    :club_name,
    :title,
    :author,
    :procured_at,
    :retired_by,
    :retired_at
  ]

  # The fact for a registered event, whose keys may be atoms or binaries
  # (an event read back from the store is binary-keyed). Read with
  # mcl_om_wire:field/2 -- the tolerant reader the corpus's Demon 65
  # prescribes for anything that may arrive wire-shaped.
  def member_registered(event), do: build(@member_fields, event)
  def book_procured(event), do: build(@book_fields, event)
  def book_retired(event), do: build(@retired_fields, event)

  defp build(fields, event) do
    Map.new(fields, fn field -> {field, :mcl_om_wire.field(field, event)} end)
  end

  # Text as CBOR text, booleans as 1/0, numbers as they are.
  def to_wire(b) when is_binary(b), do: {:text, b}
  def to_wire(true), do: 1
  def to_wire(false), do: 0
  def to_wire(l) when is_list(l), do: Enum.map(l, &to_wire/1)
  def to_wire(m) when is_map(m), do: Map.new(m, fn {k, v} -> {k, to_wire(v)} end)
  def to_wire(other), do: other

  def topic(realm_name, :member_registered) do
    :macula_topic.app_fact(realm_name, @org, @domain, "member", "member_registered", @version)
  end

  def topic(realm_name, :book_procured) do
    :macula_topic.app_fact(realm_name, @org, @domain, "book", "book_procured", @version)
  end

  def topic(realm_name, :book_retired) do
    :macula_topic.app_fact(realm_name, @org, @domain, "book", "book_retired", @version)
  end

  # The realm whose name the topics carry: io.macula for this fleet. The
  # same constant the config derives the pool's realm tag from.
  def realm_name, do: "io.macula"
end
