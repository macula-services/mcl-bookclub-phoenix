defmodule ProjectBookclub.BookclubChanged do
  # The pubsub seam: one message shape, owned here (the PRJ division writes
  # the read model, so it announces when the read model changed).
  #
  # Every projection broadcasts AFTER a successful write, on the one topic
  # the LiveView admin subscribes to. The payload names the table, the
  # event type and the affected row's id -- the LiveView decides what to do
  # with it (prepend to the feed, re-run a lookup on that id), it never
  # re-derives business meaning from the message.
  @moduledoc false

  @topic "bookclub:changed"

  def topic, do: @topic

  def broadcast(table, event_type, id) do
    # Matched, not returned: the registry is started by this very app's
    # supervisor, so a broadcast while the app runs cannot fail -- and a
    # match that surprises us here is a crash worth hearing, not an error
    # worth swallowing (the whiteboard's own seam does the same).
    :ok =
      Phoenix.PubSub.broadcast(
        MclBookclubPhoenixWeb.PubSub,
        @topic,
        {:bookclub_changed, %{table: table, event_type: event_type, id: id}}
      )

    :ok
  end
end
