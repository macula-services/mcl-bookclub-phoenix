defmodule MclBookclubPhoenix.FactsContractTest do
  # The wire contract this service publishes: the three fact topics, as
  # the literal strings a peer on another node must use, asserted as
  # literals on purpose -- a test that rebuilt them with Facts.topic/2
  # would pass whatever the builder did.
  use ExUnit.Case, async: true

  alias MclBookclubPhoenix.Facts

  @prefix "io.macula/mcl-bookclub/bookclub/"

  test "one topic per fact kind, ids and names in the payload never the topic" do
    assert Facts.topic("io.macula", :member_registered) ==
             @prefix <> "member/member_registered_v1"

    assert Facts.topic("io.macula", :book_procured) ==
             @prefix <> "book/book_procured_v1"

    assert Facts.topic("io.macula", :book_retired) ==
             @prefix <> "book/book_retired_v1"
  end

  test "every topic passes macula's own validator" do
    topics = [
      Facts.topic("io.macula", :member_registered),
      Facts.topic("io.macula", :book_procured),
      Facts.topic("io.macula", :book_retired)
    ]

    assert Enum.all?(topics, &(:macula_topic.validate(&1) == :ok)), inspect(topics)
  end

  test "the realm name is the one the pool's tag is derived from" do
    assert Facts.realm_name() == "io.macula"
  end

  test "a fact reads tolerantly across atom and binary keys" do
    atom_keyed = %{member_id: "m", club_id: "c", club_name: "N", name: "Bea", registered_at: 1}
    binary_keyed = Map.new(atom_keyed, fn {k, v} -> {Atom.to_string(k), v} end)

    assert Facts.member_registered(atom_keyed) == Facts.member_registered(binary_keyed)
  end

  test "to_wire makes text CBOR text and booleans 1/0" do
    assert Facts.to_wire("bea") == {:text, "bea"}
    assert Facts.to_wire(true) == 1
    assert Facts.to_wire(false) == 0
    assert Facts.to_wire(7) == 7
    assert Facts.to_wire(%{a: "b"}) == %{a: {:text, "b"}}
  end

  test "the mesh emitters skip replay" do
    for emitter <- [
          MclBookclubPhoenix.EmitMemberRegisteredV1ToMesh,
          MclBookclubPhoenix.EmitBookProcuredV1ToMesh,
          MclBookclubPhoenix.EmitBookRetiredV1ToMesh
        ] do
      assert emitter.replay_policy() == :skip, inspect(emitter)
    end
  end

  test "the emitters listen for exactly their own event type" do
    assert MclBookclubPhoenix.EmitMemberRegisteredV1ToMesh.interested_in() == [
             "member_registered_v1"
           ]

    assert MclBookclubPhoenix.EmitBookProcuredV1ToMesh.interested_in() == ["book_procured_v1"]
    assert MclBookclubPhoenix.EmitBookRetiredV1ToMesh.interested_in() == ["book_retired_v1"]
  end
end
