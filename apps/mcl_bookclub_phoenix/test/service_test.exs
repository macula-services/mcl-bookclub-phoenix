defmodule MclBookclubPhoenix.ServiceTest do
  # The service contract, asserted locally: the callbacks, their shapes,
  # and the store wiring the facade must export.
  use ExUnit.Case, async: true

  alias MclBookclubPhoenix.Service

  test "every required callback is exported" do
    for {fun, arity} <- [
          {:info, 0}, {:start, 1}, {:stop, 1}, {:health, 0},
          {:capabilities, 0}, {:identity_spec, 0}
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

  test "nothing is announced or asked for yet" do
    assert Service.capabilities() == []
    assert %{scope: scope, actions: [], resources: []} = Service.identity_spec()
    assert scope == "mcl-bookclub"
  end
end
