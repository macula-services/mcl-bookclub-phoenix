defmodule MclBookclubPhoenixWeb.AdminLive do
  # The LAN admin console: the LiveView twin of the Erlang bookclub's
  # task-based admin UI. Presentation ONLY:
  #
  # - every task button dispatches through the division's entry point (the
  #   maybe_ desks), so the UI can never do anything the domain does not
  #   already allow;
  # - every lookup calls a query desk;
  # - live updates arrive over the pubsub seam: the projections broadcast
  #   "changed" after each write and this LiveView subscribes (the
  #   whiteboard's pattern). This module never touches evoq, the stores,
  #   or the mesh.
  #
  # Everything the template renders is decided state computed here
  # (lookup_text, the feed entries) -- the template only prints it.
  use Phoenix.LiveView

  alias HostBookclub.ArchiveBookclub.MaybeArchiveBookclub
  alias HostBookclub.FinishReading.MaybeFinishReading
  alias HostBookclub.InitiateBookclub.{InitiateBookclubV1, MaybeInitiateBookclub}
  alias HostBookclub.PlanParty.MaybePlanParty
  alias HostBookclub.ProcureBook.{MaybeProcureBook, ProcureBookV1}
  alias HostBookclub.RegisterMember.{MaybeRegisterMember, RegisterMemberV1}
  alias HostBookclub.RetireBook.MaybeRetireBook
  alias HostBookclub.StartReading.{MaybeStartReading, StartReadingV1}
  alias HostBookclub.UnregisterMember.MaybeUnregisterMember
  alias ProjectBookclub.BookclubChanged
  alias QueryBookclub.GetBookById.GetBookById
  alias QueryBookclub.GetBookclubById.GetBookclubById
  alias QueryBookclub.GetMemberById.GetMemberById
  alias QueryBookclub.GetReadingById.GetReadingById
  alias QueryBookclub.GetReadingsByMember.GetReadingsByMember

  @feed_limit 40

  @lookup_kinds [
    {"club", "Club"},
    {"member", "Member"},
    {"book", "Book"},
    {"reading", "Reading"},
    {"readings_by_member", "Member's readings"}
  ]

  # The task list, mirrored from the Erlang admin's own TASKS table: the
  # same nine commands, the same fields, the same defaults.
  def tasks do
    [
      %{
        id: "initiate",
        label: "Initiate a club",
        fields: [
          {:club_id, "Club id (minted when empty)", ""},
          {:name, "Name", ""},
          {:initiated_by, "Initiated by", "raf"}
        ]
      },
      %{id: "plan_party", label: "Plan a party", fields: [{:club_id, "Club id", ""}]},
      %{
        id: "archive",
        label: "Archive a club",
        fields: [{:club_id, "Club id", ""}, {:archived_by, "Archived by", "raf"}]
      },
      %{
        id: "register",
        label: "Register a member",
        fields: [
          {:club_id, "Club id", ""},
          {:member_id, "Member id (minted when empty)", ""},
          {:name, "Name", ""}
        ]
      },
      %{
        id: "unregister",
        label: "Unregister a member",
        fields: [{:member_id, "Member id", ""}, {:unregistered_by, "Unregistered by", "raf"}]
      },
      %{
        id: "procure",
        label: "Procure a book",
        fields: [
          {:club_id, "Club id", ""},
          {:book_id, "Book id (minted when empty)", ""},
          {:title, "Title", ""},
          {:author, "Author", ""}
        ]
      },
      %{
        id: "retire",
        label: "Retire a book",
        fields: [{:book_id, "Book id", ""}, {:retired_by, "Retired by", "raf"}]
      },
      %{
        id: "start",
        label: "Start a reading",
        fields: [
          {:member_id, "Member id", ""},
          {:book_id, "Book id", ""},
          {:reading_id, "Reading id (minted when empty)", ""}
        ]
      },
      %{
        id: "finish",
        label: "Finish a reading",
        fields: [{:reading_id, "Reading id", ""}, {:pages_read, "Pages read", ""}]
      }
    ]
  end

  def lookup_kinds, do: @lookup_kinds

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(tasks: tasks(), lookup_kinds: lookup_kinds())
      |> assign(feed: [], lookup_kind: nil, lookup_id: nil, lookup_text: nil)
      |> assign(page_title: "mcl-bookclub — Admin")

    socket =
      if connected?(socket) do
        :ok = Phoenix.PubSub.subscribe(MclBookclubPhoenixWeb.PubSub, BookclubChanged.topic())
        socket
      else
        socket
      end

    {:ok, socket}
  end

  # One handler for every task, since every task is the same shape: run
  # the entry point, flash the outcome, feed it. The task id in the
  # hidden field tells run_task/2 which desk to dispatch.
  @impl true
  def handle_event("run", %{"task" => task_id} = params, socket) do
    label = task_label(task_id)

    case run_task(task_id, params) do
      {:ok, version} ->
        entry = feed_entry("✓ #{label} — version #{version}")

        socket =
          socket
          |> put_flash(:info, "#{label}: accepted (version #{version})")
          |> prepend_feed(entry)

        {:noreply, socket}

      {:error, reason} ->
        entry = feed_entry("✗ #{label} — #{inspect(reason)}")

        socket =
          socket
          |> put_flash(:error, "#{label}: #{inspect(reason)}")
          |> prepend_feed(entry)

        {:noreply, socket}
    end
  end

  def handle_event("lookup", %{"kind" => kind, "_id" => id}, socket) do
    id = String.trim(id)

    socket =
      assign(socket,
        lookup_kind: kind,
        lookup_id: id,
        lookup_text: lookup_text(lookup(kind, id))
      )

    {:noreply, socket}
  end

  # Live half of the picture: every projection broadcasts
  # {:bookclub_changed, change} on the pubsub seam after a successful
  # write. This LiveView prepends it to the feed, and -- when the change
  # is about the exact id the operator is currently looking at -- re-runs
  # that lookup, so the panel follows the write without any eager
  # re-query in the run handler (which would race the projection).
  @impl true
  def handle_info({:bookclub_changed, change}, socket) do
    socket =
      socket
      |> prepend_feed(feed_entry("#{change.event_type} → #{change.id}"))
      |> refresh_lookup_if(change)

    {:noreply, socket}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp refresh_lookup_if(socket, %{id: id}) do
    if socket.assigns.lookup_id != nil and socket.assigns.lookup_id == id do
      assign(socket, lookup_text: lookup_text(lookup(socket.assigns.lookup_kind, id)))
    else
      socket
    end
  end

  # ====================================================================
  # The task dispatch table
  # ====================================================================

  # Each clause builds the atom-keyed command params from the form's
  # string-keyed values, mints ids the operator left empty, and stamps the
  # club's NAME into the fact-producing commands -- the entry point is
  # where a command payload MAY consult the read model (the corpus's one
  # sanctioned place): the operator names a club by id, and the command
  # carries the club's name too, so the fact a downstream consumer
  # receives is self-contained.
  def run_task("initiate", params) do
    cmd_params =
      %{
        club_id: params["club_id"] || "",
        name: params["name"] || "",
        initiated_by: params["initiated_by"] || ""
      }
      |> mint_if_empty(:club_id, &InitiateBookclubV1.mint_club_id/0)

    dispatch(MaybeInitiateBookclub, cmd_params)
  end

  def run_task("plan_party", params) do
    dispatch(MaybePlanParty, %{club_id: params["club_id"] || ""})
  end

  def run_task("archive", params) do
    dispatch(MaybeArchiveBookclub, %{
      club_id: params["club_id"] || "",
      archived_by: params["archived_by"] || ""
    })
  end

  def run_task("register", params) do
    cmd_params =
      %{
        member_id: params["member_id"] || "",
        club_id: params["club_id"] || "",
        name: params["name"] || "",
        club_name: ""
      }
      |> mint_if_empty(:member_id, &RegisterMemberV1.mint_member_id/0)
      |> enrich_club_name()

    dispatch(MaybeRegisterMember, cmd_params)
  end

  def run_task("unregister", params) do
    dispatch(MaybeUnregisterMember, %{
      member_id: params["member_id"] || "",
      unregistered_by: params["unregistered_by"] || ""
    })
  end

  def run_task("procure", params) do
    cmd_params =
      %{
        book_id: params["book_id"] || "",
        club_id: params["club_id"] || "",
        title: params["title"] || "",
        author: params["author"] || "",
        club_name: ""
      }
      |> mint_if_empty(:book_id, &ProcureBookV1.mint_book_id/0)
      |> enrich_club_name()

    dispatch(MaybeProcureBook, cmd_params)
  end

  def run_task("retire", params) do
    dispatch(MaybeRetireBook, %{
      book_id: params["book_id"] || "",
      retired_by: params["retired_by"] || ""
    })
  end

  def run_task("start", params) do
    cmd_params =
      %{
        reading_id: params["reading_id"] || "",
        member_id: params["member_id"] || "",
        book_id: params["book_id"] || ""
      }
      |> mint_if_empty(:reading_id, &StartReadingV1.mint_reading_id/0)

    dispatch(MaybeStartReading, cmd_params)
  end

  def run_task("finish", params) do
    case Integer.parse(params["pages_read"] || "") do
      {pages, ""} ->
        dispatch(MaybeFinishReading, %{
          reading_id: params["reading_id"] || "",
          pages_read: pages
        })

      _ ->
        {:error, :invalid_pages}
    end
  end

  def run_task(unknown, _params), do: {:error, {:unknown_task, unknown}}

  defp dispatch(desk, params) do
    case desk.dispatch(params) do
      {:ok, version, _events} -> {:ok, version}
      {:error, reason} -> {:error, reason}
    end
  end

  # A missing or empty id field is minted by the desk's own mint function
  # -- the API boundary's decision, same as the Erlang admin's `_api'
  # entry points.
  defp mint_if_empty(params, field, mint_fun) do
    if blank?(Map.get(params, field)) do
      Map.put(params, field, mint_fun.())
    else
      params
    end
  end

  defp blank?(nil), do: true
  defp blank?(""), do: true
  defp blank?(_), do: false

  defp enrich_club_name(%{club_name: name} = params) when name != "", do: params

  defp enrich_club_name(params) do
    with true <- params.club_id != "",
         {:ok, club} <- GetBookclubById.find(params.club_id) do
      %{params | club_name: club.name}
    else
      _ -> params
    end
  end

  # ====================================================================
  # The lookup table
  # ====================================================================

  defp lookup("club", id), do: GetBookclubById.find(id)
  defp lookup("member", id), do: GetMemberById.find(id)
  defp lookup("book", id), do: GetBookById.find(id)
  defp lookup("reading", id), do: GetReadingById.find(id)
  defp lookup("readings_by_member", id), do: GetReadingsByMember.find(id)
  defp lookup(_kind, _id), do: {:error, :missing_id}

  defp lookup_text({:ok, result}), do: inspect(result, pretty: true, limit: :infinity)
  defp lookup_text({:error, reason}), do: "not found — #{inspect(reason)}"

  # ====================================================================
  # The feed
  # ====================================================================

  defp task_label(task_id) do
    case Enum.find(tasks(), &(&1.id == task_id)) do
      nil -> task_id
      task -> task.label
    end
  end

  defp feed_entry(text) do
    at =
      DateTime.utc_now()
      |> DateTime.to_time()
      |> Time.to_string()

    %{at: at, text: text}
  end

  defp prepend_feed(socket, entry) do
    update(socket, :feed, fn feed -> Enum.take([entry | feed], @feed_limit) end)
  end
end
