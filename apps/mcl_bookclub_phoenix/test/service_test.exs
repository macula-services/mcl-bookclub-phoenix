defmodule MclBookclubPhoenix.ServiceTest do
  # The service contract, asserted locally: the callbacks, their shapes,
  # and the store wiring the facade must export.
  use ExUnit.Case, async: true

  alias MclBookclubPhoenix.Service

  test "every required callback is exported" do
    for {fun, arity} <- [
          {:info, 0},
          {:start, 1},
          {:stop, 1},
          {:health, 0},
          {:capabilities, 0},
          {:identity_spec, 0}
        ] do
      assert function_exported?(Service, fun, arity), "missing #{fun}/#{arity}"
    end
  end

  test "info carries the three keys and the shared wire name" do
    %{name: name, version: version, description: description} = Service.info()
    assert is_binary(name) and is_binary(version) and is_binary(description)
    # The SAME wire name as the Erlang bookclub: the contract is shared.
    assert name == "mcl-bookclub"
  end

  test "the store callbacks are exported, together" do
    assert function_exported?(Service, :store_id, 0)
    assert function_exported?(Service, :data_dir, 0)
    assert is_atom(Service.store_id())

    # A CHARLIST, not a binary: the dets/ra layer under reckon-db rejects
    # a binary file option with {badarg, ...}.
    assert is_list(Service.data_dir())
  end

  test "the capability is the Erlang twin's, name for name" do
    # get_bookclub_by_id, the same procedure the Erlang bookclub advertises
    # -- a peer cannot tell the two apart by the procedure name.
    assert [
             %{
               name: "get_bookclub_by_id",
               version: 1,
               handler: {MclBookclubPhoenix.GetBookclubByIdHandler, []},
               auth: :open
             }
           ] = Service.capabilities()
  end

  test "the identity spec asks for exactly what the contract needs" do
    # One procedure, three fact topics -- popped, an attacker gains
    # precisely this and no more.
    assert %{
             scope: "mcl-bookclub",
             actions: ["get_bookclub_by_id"],
             resources: resources,
             ttl_days: 30
           } = Service.identity_spec()

    assert Enum.sort(resources) == [
             "bookclub/book/book_procured_v1",
             "bookclub/book/book_retired_v1",
             "bookclub/member/member_registered_v1"
           ]
  end

  test "the identity spec's actions match the capabilities, one for one" do
    advertised = Enum.map(Service.capabilities(), & &1.name)
    asked = Service.identity_spec().actions
    assert Enum.sort(advertised) == Enum.sort(asked)
  end
end
