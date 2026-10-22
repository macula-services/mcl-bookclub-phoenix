"""Generate mcl-bookclub-phoenix's two C4 diagrams into assets/.

Run:  python3 architecture/c4_diagrams.py

  c4-context.svg     Level 1: what the service talks to
  c4-components.svg  Level 2: what it is made of

Drawn from the code, never from a template: the five umbrella apps and their
application modules, the contract in service.ex, the store in event_store.ex, the
handler, the three emitters in the facade supervisor, the LiveView console and its
router, the deps in the five mix.exs files, and the ports, paths and variables in
the Containerfile and config/runtime.exs. When one of those changes, the diagram
changes in the same commit.

Colours are plain classes with a prefers-color-scheme: dark block, no CSS custom
properties (rsvg-convert renders those black), so the SVGs render the same on
GitHub, in IDE previews and through rsvg-convert. After a change, render each
(rsvg-convert -w 1400 assets/c4-context.svg -o /tmp/c.png) and look at it; keep
architecture/README.md's tables in step.
"""
import os
from xml.sax.saxutils import escape

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")

SANS = '"Atkinson Hyperlegible", "Segoe UI", system-ui, -apple-system, Helvetica, Arial, sans-serif'
MONO = '"JetBrains Mono", ui-monospace, Menlo, Consolas, monospace'

# Element kinds, each (light fill, light stroke, dark fill, dark stroke).
KINDS = {
    "b-sys": ("#F5E9CC", "#A56F0A", "#3A2E13", "#E3AA3C"),   # in scope
    "b-per": ("#E3EBF2", "#3B5B7A", "#1D2A36", "#8EB4D8"),   # person
    "b-mac": ("#E6E4EE", "#5E5A78", "#26243A", "#A9A4C8"),   # Macula infrastructure
    "b-lib": ("#E7F0E8", "#4A7A55", "#1A241C", "#8FBE9B"),   # library
    "b-ext": ("#ECEFED", "#8A9791", "#1C2421", "#7D8B85"),   # external system
    "b-cmp": ("#FFFFFF", "#8A9791", "#171F1C", "#7D8B85"),   # component or container
}

STYLE = f"""<style>
.t-name {{ font-family: {SANS}; font-size: 15px; font-weight: 700; }}
.t-desc {{ font-family: {SANS}; font-size: 12.5px; }}
.t-rel {{ font-family: {SANS}; font-size: 11.5px; paint-order: stroke; stroke-width: 4px; stroke-linejoin: round; }}
.t-code {{ font-family: {MONO}; font-size: 13px; font-weight: 600; }}
.t-type {{ font-family: {MONO}; font-size: 11.5px; }}
.t-bound {{ font-family: {MONO}; font-size: 12px; font-weight: 600; }}
.t-leg {{ font-family: {SANS}; font-size: 12px; }}
.edge {{ fill: none; stroke-width: 1.25; }}
.edge-later {{ fill: none; stroke-width: 1.25; stroke-dasharray: 5 4; }}
.bg {{ fill: #FFFFFF; }}
""" + "".join(f".{k} {{ fill: {v[0]}; stroke: {v[1]}; stroke-width: {2 if k == 'b-sys' else 1.25}; }}\n" for k, v in KINDS.items()) + """\
.b-later { fill: none; stroke: #8A9791; stroke-width: 1.25; stroke-dasharray: 5 4; }
.bound { fill: none; stroke: #B3BDB8; stroke-width: 1; }
.head { fill: #3B5B7A; }
.t-name, .t-code { fill: #16201D; }
.t-type, .t-bound, .t-leg { fill: #66736E; }
.t-desc { fill: #34413C; }
.t-rel { fill: #66736E; stroke: #FFFFFF; }
.edge, .edge-later { stroke: #8A9791; }
.arrowhead { fill: #8A9791; }
@media (prefers-color-scheme: dark) {
.bg { fill: #171F1C; }
""" + "".join(f".{k} {{ fill: {v[2]}; stroke: {v[3]}; }}\n" for k, v in KINDS.items()) + """\
.b-later { stroke: #7D8B85; }
.bound { stroke: #4A5752; }
.head { fill: #8EB4D8; }
.t-name, .t-code { fill: #E6ECE9; }
.t-type, .t-bound, .t-leg { fill: #93A09A; }
.t-desc { fill: #C3CDC8; }
.t-rel { fill: #93A09A; stroke: #171F1C; }
.edge, .edge-later { stroke: #7D8B85; }
.arrowhead { fill: #7D8B85; }
}
</style>"""

DEFS = ('<defs><marker id="a" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
        'orient="auto-start-reverse"><path class="arrowhead" d="M0 0L10 5L0 10z"/></marker></defs>')

LEGEND = [("b-sys", "In scope"), ("b-per", "Person"), ("b-mac", "Macula infrastructure"),
          ("b-lib", "Library"), ("b-ext", "External system"), ("b-cmp", "Container or component")]
BOUNDARY = ("bound", "Boundary")


class Diagram:
    def __init__(self, name, title, w, h):
        self.name, self.title, self.w, self.h, self.parts = name, title, w, h, []

    def text(self, cls, x, y, s, anchor=None, rotate=None):
        a = f' text-anchor="{anchor}"' if anchor else ""
        r = f' transform="rotate({rotate} {x} {y})"' if rotate is not None else ""
        self.parts.append(f'<text class="{cls}" x="{x}" y="{y}"{a}{r}>{escape(s)}</text>')

    def box(self, cls, x, y, w, h, name, kind, desc, person=False, code=False):
        # A box that is too small for its own words renders as text on top of the
        # next box, which no test would catch and a reader would read as the
        # diagram saying something it does not. Fail here instead.
        need = 70 + 16 * max(len(desc) - 1, 0) + 18
        if h < need:
            raise ValueError(f"{self.name}: {name} needs height {need}, has {h}")
        for line in desc:
            if 16 + 6.2 * len(line) > w - 16:
                raise ValueError(f"{self.name}: {name}: '{line}' is wider than {w - 32}px")
        self.parts.append(f'<rect class="{cls}" x="{x}" y="{y}" width="{w}" height="{h}" rx="10"/>')
        tx = x + 16
        if person:
            self.parts.append(f'<circle class="head" cx="{x + 26}" cy="{y + 24}" r="9"/>')
            tx = x + 44
        self.text("t-code" if code else "t-name", tx, y + 28, name)
        self.text("t-type", tx, y + 46, kind)
        for i, line in enumerate(desc):
            self.text("t-desc", x + 16, y + 70 + 16 * i, line)

    def bound(self, x, y, w, h, label):
        self.parts.append(f'<rect class="bound" x="{x}" y="{y}" width="{w}" height="{h}" rx="12"/>')
        self.text("t-bound", x + 16, y + 22, label)

    def edge(self, d, later=False):
        self.parts.append(f'<path class="{"edge-later" if later else "edge"}" d="{d}" marker-end="url(#a)"/>')

    def legend(self, y, boundary=True):
        x = 24
        for cls, label in LEGEND + ([BOUNDARY] if boundary else []):
            self.parts.append(f'<rect class="{cls}" x="{x}" y="{y}" width="22" height="14" rx="3"/>')
            self.text("t-leg", x + 30, y + 12, label)
            x += 34 + 6.6 * len(label)

    def write(self):
        svg = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" role="img" '
               f'aria-label="{escape(self.title)}">', f"<title>{escape(self.title)}</title>", STYLE, DEFS,
               f'<rect class="bg" x="0" y="0" width="{self.w}" height="{self.h}"/>'] + self.parts + ["</svg>", ""]
        with open(os.path.join(OUT, self.name), "w") as f:
            f.write("\n".join(svg))


def context():
    d = Diagram("c4-context.svg", "mcl-bookclub-phoenix system context", 1000, 700)
    d.box("b-per", 40, 30, 270, 120, "Club operator", "[Person]",
          ["Runs the club from the LiveView", "console: initiates, registers",
           "members, procures, plans parties"], person=True)
    d.box("b-per", 690, 30, 270, 120, "Mesh consumer", "[Person, app or service]",
          ["Calls mcl-bookclub/", "get_bookclub_by_id and",
           "subscribes to the fact topics"], person=True)
    d.box("b-sys", 365, 186, 270, 152, "mcl-bookclub-phoenix", "[mcl_om mesh service, own box]",
          ["Five umbrella apps: CMD, PRJ, QRY,", "the facade and the web console.",
           "Serves one procedure of its own on", "the mesh, the LiveView admin on",
           "4000, and /health on 8454"])
    d.box("b-ext", 40, 400, 270, 120, "Host disk", "[External system]",
          ["The club store and sqlite read", "model under /var/lib, the node",
           "key under /etc/mcl/secrets"])
    d.box("b-mac", 365, 400, 270, 120, "macula-realm", "[Macula infrastructure]",
          ["Endorses the node's identity key", "and grants the scope mcl-bookclub:",
           "one action, three fact topics"])
    d.box("b-mac", 690, 400, 270, 120, "Macula stations, mesh DHT", "[Macula infrastructure]",
          ["Pinned stations are the mesh entry", "(QUIC); the DHT holds the",
           "adverts, and carries the facts"])
    d.edge("M175 150V176H400V186")
    d.text("t-rel", 183, 170, "commands on 4000, and reads")
    d.edge("M825 150V176H620V186")
    d.text("t-rel", 690, 170, "calls get_bookclub_by_id")
    d.edge("M420 338V400"); d.text("t-rel", 428, 370, "boot claim, scope")
    d.edge("M620 338V368H825V400"); d.text("t-rel", 632, 360, "advertises, publishes 3 facts")
    d.edge("M365 300H340V460H310")
    d.text("t-rel", 330, 340, "keeps the log and the read model", anchor="middle", rotate=-90)
    d.text(
        "t-desc",
        40,
        566,
        "Same org, topics and procedure names as the Erlang bookclub, so a peer cannot tell the two apart. The",
    )
    d.text(
        "t-desc",
        40,
        584,
        "three divisions have no Phoenix in their deps: only the web app presents, and it dispatches the same desks.",
    )
    d.legend(630, boundary=False)
    d.write()


def components():
    d = Diagram("c4-components.svg", "mcl-bookclub-phoenix components", 1340, 1420)
    d.bound(16, 40, 1292, 840, "mcl-bookclub-phoenix [Container] - one umbrella, five apps")
    # Row 1: the boot, the contract, the facade tree.
    d.box("b-cmp", 32, 76, 340, 136, "MclBookclubPhoenix.Application", "[OTP application]",
          ["Opens the store from Service.event_store/0,",
           "then mcl_om:boot/1 with the service module;",
           "a store that cannot open stops the boot"], code=True)
    d.box("b-sys", 492, 76, 340, 136, "MclBookclubPhoenix.Service", "[mcl_om_service behaviour]",
          ["The six callbacks plus event_store/0:",
           "info, start, stop, health, capabilities,",
           "identity_spec"], code=True)
    d.box("b-cmp", 952, 76, 340, 136, "MclBookclubPhoenix.Supervisor", "[supervisor, one_for_one]",
          ["Three children, the emitters. Started by",
           "Service.start/1, after boot's replay,",
           "which is harmless for :skip handlers"], code=True)
    # Row 2: the store, the mesh handler, the emitters.
    d.box("b-cmp", 32, 272, 340, 136, "MclBookclubPhoenix.EventStore", "[this service's reckon-db store]",
          ["start_store, wait until reckon_db lists it,",
           "then :evoq_store_subscription, the one",
           "subscription that feeds every handler"], code=True)
    d.box("b-sys", 492, 272, 340, 136, "MclBookclubPhoenix.GetBookclubByIdHandler", "[macula_response]",
          ["handle_request/2 reads club_id with",
           "mcl_om_wire:field/2 and answers from the",
           "QRY desk; text back as CBOR text"], code=True)
    d.box("b-cmp", 952, 272, 340, 136, "EmitMemberRegisteredV1ToMesh", "[evoq_event_handler, three modules]",
          ["with EmitBookProcuredV1ToMesh and",
           "EmitBookRetiredV1ToMesh: replay_policy",
           ":skip, publish through Facts and :macula"], code=True)
    # Row 3: the three divisions.
    d.box("b-cmp", 32, 468, 340, 180, "project_bookclub", "[PRJ division]",
          ["Starts the pubsub registry, the read-model",
           "store and eight projections; one",
           "INSERT OR REPLACE per event, and a",
           "broadcast on PubSub after each write.",
           "No Phoenix in its deps: just the pubsub lib"], code=True)
    d.box("b-cmp", 492, 468, 340, 180, "host_bookclub", "[CMD division]",
          ["Nine desks, four aggregates, the",
           "on_member_registered policy; commands",
           "dispatch through evoq to the store.",
           "NO mesh SDK in its deps, which is why",
           "the emitters live in the facade"], code=True)
    d.box("b-cmp", 952, 468, 340, 180, "query_bookclub", "[QRY division]",
          ["BookclubQueryStore: one GenServer, q/2",
           "only, so a query module cannot write.",
           "Five pure query modules answer with",
           "maps. NO evoq, NO mesh, NO Phoenix in",
           "its deps"], code=True)
    # Row 4: the presentation app.
    d.text("t-desc", 32, 700, "mcl_bookclub_phoenix_web - presentation only:")
    d.box("b-cmp", 32, 708, 340, 136, "MclBookclubPhoenixWeb.Endpoint", "[Phoenix endpoint]",
          ["MCL_HTTP_PORT, 0.0.0.0:4000; the LiveView",
           "socket at /live; no other plug reads or",
           "writes the club"], code=True)
    d.box("b-cmp", 492, 708, 340, 136, "MclBookclubPhoenixWeb.Router", "[one live route]",
          ["the browser pipeline, then / serves",
           "MclBookclubPhoenixWeb.AdminLive; nothing",
           "else is routed"], code=True)
    d.box("b-cmp", 952, 708, 340, 136, "MclBookclubPhoenixWeb.AdminLive", "[LiveView, presentation only]",
          ["Every task button dispatches a maybe_",
           "desk, every lookup calls a query desk,",
           "and the feed arrives over pubsub"], code=True)
    # The libraries.
    d.text("t-desc", 32, 916, "The libraries the release links:")
    d.box("b-lib", 32, 930, 300, 136, "mcl_om + macula", "[~> 1.4, ~> 16.0]",
          ["boot/1: node key, realm join;",
           "QUIC pool, health, adverts;",
           "publish on a fact topic"], code=True)
    d.box("b-lib", 352, 930, 300, 136, "reckon_db + evoq", "[~> 5.11, ~> 1.27]",
          ["the event log and the CQRS", "framework; reckon_evoq ~> 2.8",
           "is the adapter between them"], code=True)
    d.box("b-lib", 672, 930, 300, 136, "esqlite + phoenix_pubsub", "[~> 0.9, ~> 2.3]",
          ["one sqlite file per store, and", "the registry PRJ broadcasts on",
           "and the LiveView subscribes to"], code=True)
    d.box("b-lib", 992, 930, 300, 136, "phoenix + live_view", "[~> 1.8, ~> 1.2]",
          ["the console; bandit ~> 1.12", "serves it and jason ~> 1.4",
           "encodes, esbuild bundles app.js"], code=True)
    # The host's environment.
    d.box("b-ext", 32, 1106, 600, 104, "MCL_DATA_DIR", "[environment, /var/lib/mcl-bookclub]",
          ["read by event_store/0 and both sqlite stores; the log at",
           "<dir>/mcl_bookclub_store, the read model at <dir>/bookclub.sqlite3"], code=True)
    d.box("b-ext", 652, 1106, 640, 104, "MCL_HTTP_PORT, MCL_HEALTH_PORT", "[environment, 4000 and 8454]",
          ["the Endpoint binds 0.0.0.0:4000 and /health is answered on",
           "8454; the Erlang twin owns 8488, so a shared box needs both"], code=True)
    d.box("b-ext", 32, 1238, 1260, 104,
          "MCL_REALM_NAME, MCL_REALM_KEY, MCL_IDENTITY_KEY_PATH, SECRET_KEY_BASE",
          "[environment, config/runtime.exs]",
          ["the realm tag is derived from MCL_REALM_NAME here, not passed in; a prod boot refuses",
           "to start without SECRET_KEY_BASE, and the node key lives on the mounted secrets volume"], code=True)
    # The wiring between the boxes.
    d.edge("M372 160H492"); d.text("t-rel", 432, 152, "event_store/0", anchor="middle")
    d.edge("M832 190H952"); d.text("t-rel", 892, 182, "start/1 starts it", anchor="middle")
    d.edge("M212 212V272"); d.text("t-rel", 220, 246, "opens it first")
    d.edge("M632 212V272"); d.text("t-rel", 640, 246, "capabilities/0 names it")
    d.edge("M1112 212V272"); d.text("t-rel", 1120, 246, "three skip-policy children")
    d.edge("M212 408V468"); d.text("t-rel", 220, 442, "delivers every event")
    d.edge("M700 408V440H1112V468"); d.text("t-rel", 760, 432, "answers from the QRY desk")
    d.edge("M372 790H492"); d.text("t-rel", 432, 782, "mounts", anchor="middle")
    d.edge("M832 790H952"); d.text("t-rel", 892, 782, "live /", anchor="middle")
    d.edge("M952 760H900V672H700V648")
    d.text("t-rel", 710, 664, "task buttons dispatch the maybe_ desks")
    d.edge("M1112 708V648"); d.text("t-rel", 1120, 676, "lookups call the desks")
    d.legend(1374)
    d.write()


if __name__ == "__main__":
    for make in (context, components):
        make()
