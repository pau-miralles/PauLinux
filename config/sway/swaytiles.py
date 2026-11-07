#!/usr/bin/env python3
import contextlib
import fcntl
import glob
import itertools
import json
import math
import os
import re
import signal
import socket
import struct
import sys
import threading
import time
from pathlib import Path

STATE = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state") / "swaytiles.json"
MARK = "_layout"
AFTER = "_layout_after_"
SIZED = "_layout_sized_"
RING = "_layout_ring"
PLACING = (AFTER, SIZED, RING)
NEXT = 0
SYNC = "layout:sync"
ACT = "layout:act"

WATCH = (0.2, 4.0)
CLOSING = 1.0
TABBED = ("tabbed", "stacked")
SPLITS = {"right": "splith", "down": "splitv", "left": "splith", "up": "splitv"}
EVENTS = {0: "workspace", 1: "output", 3: "window", 5: "binding", 6: "shutdown", 7: "tick"}
SUBSCRIPTIONS = ["window", "tick", "workspace", "binding", "output", "shutdown"]
FOCUSING = re.compile(r"focus (left|right|up|down)")
MOVING = re.compile(r"move (left|right|up|down)|move (?:container |window )?(?:to )?workspace (number \d+|[^\s\"']+)")
HIDING = re.compile(r"move (?:container |window )?(?:to )?scratchpad")
FLOATING = re.compile(r"floating (toggle|enable|disable)")
ELSEWHERE = ("next", "prev", "next_on_output", "prev_on_output", "back_and_forth", "current", "number")
RESHAPING = re.compile(r"(?:^|[;,\]])\s*(?:split[hvt]?|layout)\b")


class Sway:
    MAGIC = b"i3-ipc"
    COMMAND, WORKSPACES, TREE, TICK, SUBSCRIBE, CONFIG, MODE = 0, 1, 4, 10, 2, 9, 12

    def __init__(self, path=None, timeout=None):
        self.given = path
        self.timeout = timeout
        self.lock = threading.Lock()
        self.connection = None

    @property
    def path(self):
        if not self.given:
            self.given = os.environ.get("SWAYSOCK") or discover()
        if not self.given:
            raise ConnectionError("no sway socket: SWAYSOCK is unset and no running sway was found")
        return self.given

    def connect(self):
        connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        connection.settimeout(self.timeout)
        connection.connect(self.path)
        return connection

    def send(self, connection, kind, payload=""):
        data = payload.encode()
        connection.sendall(self.MAGIC + struct.pack("=II", len(data), kind) + data)

    def receive(self, connection):
        size, kind = struct.unpack("=II", self.read(connection, 14)[len(self.MAGIC):])
        return kind & 0x7FFFFFFF, json.loads(self.read(connection, size))

    @staticmethod
    def read(connection, size):
        data = bytearray()
        while len(data) < size:
            chunk = connection.recv(size - len(data))
            if not chunk:
                raise ConnectionError("sway closed the IPC socket")
            data += chunk
        return bytes(data)

    def request(self, kind, payload=""):
        with self.lock:
            try:
                self.connection = self.connection or self.connect()
                self.send(self.connection, kind, payload)
                return self.receive(self.connection)[1]
            except BaseException:
                if self.connection:
                    self.connection.close()
                self.connection = None
                raise

    def command(self, *commands):
        joined = "; ".join(command for command in commands if command)
        if not joined:
            return []
        results = self.request(self.COMMAND, joined)
        for result in results:
            if result.get("parse_error"):
                print(f"swaytiles: sway rejected {joined!r}: {result.get('error')}", file=sys.stderr, flush=True)
        return results

    def tree(self):
        return self.request(self.TREE)

    def tick(self, payload):
        return self.request(self.TICK, payload)

    def focused_workspace(self):
        return next(ws["name"] for ws in self.request(self.WORKSPACES) if ws["focused"])

    def subscribe(self, names, pause=lambda: None):
        from select import select as readable
        connection = self.connect()
        self.send(connection, self.SUBSCRIBE, json.dumps(names))
        self.receive(connection)

        def stream():
            with connection:
                while True:
                    wait = pause()
                    if wait is not None and not readable([connection], [], [], wait)[0]:
                        yield "idle", {}
                        continue
                    kind, event = self.receive(connection)
                    yield EVENTS.get(kind), event
        return stream()


def discover():
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}")
    found = []
    for path in runtime.glob(f"sway-ipc.{os.getuid()}.*.sock"):
        try:
            if Path(f"/proc/{path.name.split('.')[2]}/comm").read_text().strip() == "sway":
                found.append((path.stat().st_mtime, str(path)))
        except (OSError, IndexError):
            continue
    return max(found)[1] if found else None


def config_path(socket_path):
    home = Path.home()
    settings = Path(os.environ.get("XDG_CONFIG_HOME") or home / ".config")
    try:
        pid = Path(socket_path).name.split(".")[2]
        arguments = Path(f"/proc/{pid}/cmdline").read_bytes().decode(errors="replace").split("\0")
        for index, argument in enumerate(arguments):
            given = argument.partition("=")[2] if argument.startswith("--config=") else None
            if argument in ("-c", "--config") and index + 1 < len(arguments):
                given = arguments[index + 1]
            if given:
                return Path(os.readlink(f"/proc/{pid}/cwd")) / given
    except (OSError, IndexError):
        pass
    places = (home / ".sway/config", settings / "sway/config", home / ".i3/config", settings / "i3/config",
              Path("/etc/sway/config"), Path("/etc/i3/config"))
    return next((path for path in places if path.is_file()), None)


def bindings(text, directory, variables=None, seen=None):
    variables = {} if variables is None else variables
    seen = set() if seen is None else seen
    found, block, depth = [], None, 0
    for line in text.replace("\\\n", "").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        words = line.split()
        if words[0] == "set" and len(words) > 2 and words[1].startswith("$") and not depth:
            line = f"set {words[1]} {replaced(line.split(None, 2)[2], variables)}"
            variables[words[1]] = line.split(None, 2)[2]
            continue
        line = replaced(line, variables)
        words = line.split()
        if depth:
            depth += (words[-1] == "{") - (line == "}")
            if block is not None and depth == 1 and line != "}" and words[-1] != "{":
                found.append(bound([*block, *words]))
        elif words[-1] == "{":
            depth, block = 1, words[:-1] if words[0] in ("bindsym", "bindcode") else None
        elif words[0] in ("bindsym", "bindcode"):
            found.append(bound(words))
        elif words[0] == "include" and len(words) > 1:
            pattern = os.path.expandvars(os.path.expanduser(line.split(None, 1)[1]))
            for name in sorted(glob.glob(os.path.join(directory, pattern))):
                path = Path(name).resolve()
                if path in seen or not path.is_file():
                    continue
                seen.add(path)
                with contextlib.suppress(OSError, UnicodeDecodeError):
                    found += bindings(path.read_text(), path.parent, variables, seen)
    return [binding for binding in found if binding]


def replaced(line, variables):
    for name in sorted(variables, key=len, reverse=True):
        line = line.replace(name, variables[name])
    return line


def bound(words):
    keys = next((index for index, word in enumerate(words) if index and not word.startswith("--")), None)
    if keys is None or keys + 1 >= len(words):
        return None
    return " ".join(words[:keys + 1]), " ".join(words[keys + 1:])


def same_keys(prefix):
    kind, *flags, keys = prefix.split()
    return kind, frozenset(flags), frozenset(keys.lower().split("+"))


def following(command):
    command = " ".join(command.split())
    if HIDING.fullmatch(command):
        return "nop layout hide"
    if command == "kill":
        return "nop layout close"
    if floating := FLOATING.fullmatch(command):
        return f"nop layout float {floating[1]}"
    match = MOVING.fullmatch(command)
    if match is None or match[2] in ELSEWHERE:
        return None
    return f"nop layout move {match[1] or match[2]}"


def flat(layout):
    return lambda ids: (layout, ids)


def tile(outer, inner, master_last=False):
    def arrange(ids):
        stack = (inner, ids[1:])
        return (outer, [stack, ids[0]] if master_last else [ids[0], stack])
    return arrange


def turning(*directions):
    def arrange(ids, step=0):
        direction = directions[step % len(directions)]
        if len(ids) < 2:
            return (SPLITS[direction], ids)
        rest = arrange(ids[1:], step + 1)
        pair = [rest, ids[0]] if direction in ("left", "up") else [ids[0], rest]
        return (SPLITS[direction], pair)
    return arrange


LAYOUTS = {
    "tabbed": flat("tabbed"),
    "master": tile("splith", "splitv"),
    "spiral": turning("right", "down", "left", "up"),
}

LEADING = ("master", "spiral")
NEW = ("stack", "master")


def normalize(node):
    if isinstance(node, int) or node is None:
        return node
    children = [child for child in map(normalize, node[1]) if child is not None]
    return (node[0], children) if children else None


def loose(node):
    if isinstance(node, int) or node is None:
        return node
    children = [child for child in map(loose, node[1]) if child is not None]
    if len(children) == 1 and node[0] not in TABBED:
        return children[0]
    return (node[0], children) if children else None


def plain(node):
    node = loose(node)
    if isinstance(node, int) or node is None:
        return node
    merged = []
    for child in map(plain, node[1]):
        nested = not isinstance(child, int) and child[0] == node[0] and node[0] not in TABBED
        merged += child[1] if nested else [child]
    return (node[0], merged)


def trimmed(node):
    node = normalize(node)
    while node and not isinstance(node, int) and len(node[1]) == 1 and node[0] not in TABBED:
        node = node[1][0]
    return node


def without(node, *cons):
    if isinstance(node, int):
        return None if node in cons else node
    return (node[0], [child for child in (without(child, *cons) for child in node[1]) if child is not None])


def parent_of(node, con):
    if isinstance(node, int):
        return None
    if con in node[1]:
        return node
    return next((parent for child in node[1] if (parent := parent_of(child, con))), None)


def lineage(node, leaf):
    if isinstance(node, int):
        return []
    for child in node[1]:
        if child == leaf:
            return [node]
        if inner := lineage(child, leaf):
            return [node, *inner]
    return []


def leaves(node):
    return [node] if isinstance(node, int) else [leaf for child in node[1] for leaf in leaves(child)]


def bare(node):
    return node if isinstance(node, int) or node is None else ("", [bare(child) for child in node[1]])


def outline(node):
    return plain(trimmed(node))


def layout_command(layout):
    return f"layout {'stacking' if layout == 'stacked' else layout}"


def ancestors(node, con):
    if node["id"] == con:
        return [node]
    return next(([node, *path] for child in node["nodes"] if (path := ancestors(child, con))), [])


def shape(node):
    return node["id"] if not node["nodes"] else (node["layout"], [shape(child) for child in node["nodes"]])


def leaf_nodes(node):
    if node["type"] == "con" and not node["nodes"]:
        return [node]
    return [leaf for child in node["nodes"] for leaf in leaf_nodes(child)]


def tiled(node):
    return [leaf["id"] for leaf in leaf_nodes(node)]


def covered(node):
    return any(child.get("fullscreen_mode") or covered(child) for child in node["nodes"] + node["floating_nodes"])


def top(workspace):
    node = workspace
    while len(node["nodes"]) == 1 and node["layout"] not in TABBED and node["nodes"][0]["nodes"]:
        node = node["nodes"][0]
    return node


def shown(node):
    if not node["nodes"]:
        return [node] if node["type"] == "con" else []
    children = node["nodes"]
    if node["layout"] in TABBED:
        children = [next((child for con in node["focus"] for child in children if child["id"] == con), children[0])]
    return [leaf for child in children for leaf in shown(child)]


def box(node):
    rect, deco = node["rect"], node["deco_rect"]["height"]
    return rect["x"], rect["y"] - deco, rect["x"] + rect["width"], rect["y"] + rect["height"]


def span(node, axis):
    return node["rect"][axis] + (node["deco_rect"]["height"] if axis == "height" else 0)


def flanks(workspace, master):
    node = top(workspace)
    children = node["nodes"]
    if node["layout"] not in ("splith", "splitv") or len(children) != 3 or children[1]["id"] != master:
        return None
    return children[0], children[2]


def gap(workspace, axis):
    node = top(workspace)
    children = node["nodes"]
    if len(children) < 2 or family(node["layout"]) != ("h" if axis == "width" else "v"):
        return 0
    return max(0, (node["rect"][axis] - sum(span(child, axis) for child in children)) // (len(children) - 1))


def sides_room(workspace, axis, share, lean):
    room = workspace["rect"][axis]
    rest = room - 2 * gap(workspace, axis) - room * share // 100
    return round(rest * lean), rest - round(rest * lean)


def balancing(workspace, master, sides, axis, share, lean):
    rooms = sides_room(workspace, axis, share, lean)
    return [*(f"[con_id={side}] resize set {axis} {size} px" for side, size in zip(sides, rooms, strict=True)),
            f"[con_id={master}] resize set {axis} {share} ppt"] * 5


def beside(workspace, node, direction, order):
    parent = ancestors(workspace, node["id"])[-2]
    if parent["layout"] == ("tabbed" if direction in ("left", "right") else "stacked"):
        siblings = parent["nodes"]
        index = [child["id"] for child in siblings].index(node["id"]) + (1 if direction in ("right", "down") else -1)
        if 0 <= index < len(siblings) and not siblings[index]["nodes"]:
            return siblings[index]["id"]
    left, upper, right, lower = box(node)
    across = direction in ("left", "right")
    found = []
    for leaf in shown(workspace):
        x1, y1, x2, y2 = box(leaf)
        distance = {"left": left - x2, "right": x1 - right, "up": upper - y2, "down": y1 - lower}[direction]
        along = min(lower, y2) - max(upper, y1) if across else min(right, x2) - max(left, x1)
        size = min(lower - upper, y2 - y1) if across else min(right - left, x2 - x1)
        if leaf["id"] != node["id"] and distance >= 0 and along > 0:
            rank = order.index(leaf["id"]) if leaf["id"] in order else len(order)
            found.append((round(distance / 10), 2 * along < size - 2, rank, leaf["id"]))
    return min(found)[3] if found else None


def named(tree, name):
    return next((ws for ws in workspaces(tree) if ws["name"] == name), None)


def windows(workspace):
    return [*leaf_nodes(workspace), *workspace["floating_nodes"]]


def everyone(node):
    found = {node["id"]} if node["type"] in ("con", "floating_con") and not node["nodes"] else set()
    for child in node["nodes"] + node["floating_nodes"]:
        found |= everyone(child)
    return found


def outputs(tree):
    return [output for output in tree["nodes"] if output["name"] != "__i3"]


def workspaces(tree):
    return [ws for output in outputs(tree) for ws in output["nodes"]]


def visible(tree):
    return {output.get("current_workspace") for output in tree["nodes"]}


def focused_node(tree):
    stack = [tree]
    while stack:
        node = stack.pop()
        if node.get("focused"):
            return node
        stack += node["nodes"] + node["floating_nodes"]
    node = tree
    while node["focus"]:
        node = next(child for child in node["nodes"] + node["floating_nodes"] if child["id"] == node["focus"][0])
    return node


def focused_window(tree):
    node = focused_node(tree)
    return node, next((ws for ws in workspaces(tree) if node in windows(ws)), None)


def invisible(tree):
    return [node["id"] for ws in workspaces(tree) for node in ws["floating_nodes"] if node.get("opacity") == 0]


def marked(node, prefix):
    found = {mark: node["id"] for mark in node.get("marks", ()) if mark.startswith(prefix)}
    for child in node["nodes"] + node["floating_nodes"]:
        found.update(marked(child, prefix))
    return found


def encoded(name):
    return name.encode().hex()


def criteria(name):
    return re.escape(name).replace('"', '\\"')


def loosely(name):
    return "".join(letter if letter.isascii() and (letter.isalnum() or letter in "_-") else "." for letter in name)


def elsewhere(name):
    return "^(?!" + loosely(name) + "$)"


def quoted(name):
    return '"' + name.replace('\\', '\\\\').replace('"', '\\"') + '"'


def build(node):
    if isinstance(node, int):
        return []
    layout, children = node
    first = leaves(node)[0]
    commands = [f"[con_id={first}] split h", f"[con_id={first}] {layout_command(layout)}",
                *after(first, *(leaves(child)[0] for child in reversed(children[1:])))]
    return commands + [command for child in children for command in build(child)]


def family(layout):
    return "h" if layout in ("splith", "tabbed") else "v" if layout in ("splitv", "stacked") else None


def extent(layout):
    return "width" if layout == "splith" else "height"


def branches(node):
    return [] if node is None or isinstance(node, int) else node[1]


def turns(current, wanted):
    if current == wanted:
        return []
    across = "up" if family(current) == "h" else "left"
    if family(wanted) != family(current):
        return [across]
    return [across, "left" if family(wanted) == "h" else "up"]


def wrapped(workspace):
    nodes = workspace["nodes"]
    return len(nodes) == 1 and bool(nodes[0]["nodes"]) and nodes[0]["layout"] not in TABBED


def assemble(workspace, target, focused=None):
    if covered(workspace):
        return None
    ids = leaves(target)
    first, rest = ids[0], ids[1:]
    layout = workspace["layout"]
    root = (layout if layout not in TABBED else "splith") if isinstance(target, int) else target[0]
    direct = [node["id"] for node in workspace["nodes"] if not node["nodes"]]
    commands = []
    if direct and first not in direct:
        commands += after(direct[0], first)
    elif not direct:
        holder = workspace["nodes"][0]
        commands += after(holder["id"], *ids)
        if not rest:
            commands.append(f"[con_id={first}] split none")
        else:
            commands.append(f"[con_id={first}] move {'left' if family(holder['layout']) == 'h' else 'up'}")
            if family(layout) != family(holder["layout"]):
                layout = "splith" if family(holder["layout"]) == "h" else "splitv"
    wanted = root if root not in TABBED else layout if layout not in TABBED else "splith"
    commands += [f"[con_id={first}] move {direction}" for direction in turns(layout, wanted)]
    if rest:
        commands += after(first, *reversed(rest))
    if root in TABBED:
        commands.append(f"[con_id={first}] {layout_command(root)}")
    if not isinstance(target, int):
        commands += [command for child in target[1] for command in build(child)]
    return commands + ([refocus(focused)] if focused in ids else [])


def after(anchor, *cons):
    return [f"[con_id={anchor}] mark --add {MARK}", *(f"[con_id={con}] move to mark {MARK}" for con in cons), f"[con_id={anchor}] unmark {MARK}"]


def refocus(con):
    return f"[con_id={con} workspace=__focused__] focus"


FRESH = itertools.count(-1, -1)


def copied(node):
    return {**node, "nodes": [copied(child) for child in node["nodes"]]}


def position(parent, node):
    return [child["id"] for child in parent["nodes"]].index(node["id"])


def container(layout, nodes):
    return {"id": next(FRESH), "type": "con", "layout": layout, "nodes": nodes, "floating_nodes": []}


def put_after(root, anchor, con):
    parent = ancestors(root, anchor)[-2]
    parent["nodes"].insert(position(parent, {"id": anchor}) + 1, {"id": con, "type": "con", "layout": "none", "nodes": [], "floating_nodes": []})


def take_out(root, con, path=None):
    path = path or ancestors(root, con)
    for parent, child in zip(reversed(path[:-1]), reversed(path[1:]), strict=True):
        parent["nodes"][:] = [node for node in parent["nodes"] if node is not child]
        if parent["nodes"] or parent is root:
            break


def enclose(root, con, layout):
    parent = ancestors(root, con)[-2]
    index = position(parent, {"id": con})
    parent["nodes"][index] = container(layout, [parent["nodes"][index]])


def move(root, con, direction):
    offset = -1 if direction in ("left", "up") else 1
    path = ancestors(root, con)
    window, level, wrapped = path[-1], len(path) - 2, False
    current = window
    while True:
        parent = path[level]
        if family(parent["layout"]) != family(SPLITS[direction]):
            if parent is root:
                wrapper = container(root["layout"], root["nodes"])
                root["nodes"], root["layout"] = [wrapper], SPLITS[direction]
                path.insert(1, wrapper)
                current, level, wrapped = wrapper, 0, True
            else:
                current, level = parent, level - 1
            continue
        index = position(parent, current)
        beside = parent["nodes"][index + offset] if 0 <= index + offset < len(parent["nodes"]) else None
        if current is not window:
            break
        if beside is not None and not beside["nodes"]:
            parent["nodes"][index], parent["nodes"][index + offset] = beside, window
            return "swap"
        if beside is not None:
            return "into"
        if parent is root:
            return "cross"
        current, level = parent, level - 1
    if beside is not None:
        return "into"
    old = path[-2]
    if not wrapped and path[-3] is root and len(old["nodes"]) == 1:
        return "cross"
    parent["nodes"].insert(position(parent, current) + (offset > 0), window)
    take_out(root, con, path)
    squash(root)
    return "out"


def squash(node):
    index = 0
    while index < len(node["nodes"]):
        child = node["nodes"][index]
        inner = child["nodes"][0] if len(child["nodes"]) == 1 else None
        if (inner is not None and {child["layout"], inner["layout"]} <= {"splith", "splitv"}
                and family(child["layout"]) != family(inner["layout"]) == family(node["layout"])):
            node["nodes"][index:index + 1] = inner["nodes"][::-1]
            index += len(inner["nodes"])
        else:
            squash(child)
            index += 1


def swap(root, first, second):
    one, other = ancestors(root, first), ancestors(root, second)
    at, to = position(one[-2], one[-1]), position(other[-2], other[-1])
    one[-2]["nodes"][at], other[-2]["nodes"][to] = other[-1], one[-1]


def bubble(root, con, others):
    for other in others:
        swap(root, con, other)
    return [f"[con_id={con}] swap container with con_id {other}" for other in others]


def reconcile(workspace, target):
    if isinstance(target, int) or target[0] in TABBED or workspace["layout"] != target[0]:
        return None
    commands = []
    if len(workspace["nodes"]) == 1 and workspace["nodes"][0]["nodes"]:
        side = next((index for index in (0, -1) if isinstance(target[1][index], int)), None)
        if side is None:
            return None
        con = leaves(shape(workspace))[side]
        way = ("left" if side == 0 else "right") if family(target[0]) == "h" else ("up" if side == 0 else "down")
        if move(workspace, con, way) != "out":
            return None
        commands.append(f"[con_id={con}] move {way}")

    lost = []

    def unwrap(parent, index):
        child = parent["nodes"][index]["nodes"][0]
        commands.append(f"[con_id={child['id']}] split none")
        parent["nodes"][index] = child
        if len(parent["nodes"]) == 1 and parent is not workspace:
            above = ancestors(workspace, parent["id"])[-2]
            if parent["layout"] in TABBED or (above is not workspace and len(above["nodes"]) == 1):
                lost.append(parent)
            commands.append(f"[con_id={child['id']}] split {family(parent['layout'])}")
            parent["id"] = next(FRESH)
        return child

    def align(parent, index, want):
        node = parent["nodes"][index]
        if isinstance(want, int):
            while len(node["nodes"]) == 1:
                node = unwrap(parent, index)
            return not node["nodes"]
        if not node["nodes"]:
            return False
        while len(node["nodes"]) == 1 and node["nodes"][0]["nodes"] and len(want[1]) > 1:
            node = unwrap(parent, index)
        if node["layout"] != want[0]:
            if node["layout"] in TABBED or want[0] in TABBED:
                return False
            turn = f"split {family(want[0])}" if len(node["nodes"]) == 1 else layout_command(want[0])
            commands.append(f"[con_id={node['nodes'][0]['id']}] {turn}")
            node["layout"] = want[0]
        return arrange(node, want[1])

    def hand_over(nodes, short):
        for index in short:
            while short[index] > 0:
                giver = next((other for other in short if short[other] < 0), None)
                if giver is None:
                    return False
                leaf = nodes[giver]["nodes"].pop()
                commands.extend(after(nodes[index]["nodes"][-1]["id"], leaf["id"]))
                nodes[index]["nodes"].append(leaf)
                short[index], short[giver] = short[index] - 1, short[giver] + 1
        return True

    def arrange(node, wanted):
        nodes = node["nodes"]
        lines = [child for child in nodes if child["nodes"] and all(not leaf["nodes"] for leaf in child["nodes"])]
        if len(nodes) > len(wanted) and len(lines) == len(nodes) and all(
                not isinstance(want, int) and all(isinstance(leaf, int) for leaf in want[1]) for want in wanted):
            needs = [len(want[1]) for want in wanted] + [0] * (len(nodes) - len(wanted))
            if not hand_over(nodes, {index: need - len(child["nodes"]) for index, (need, child) in enumerate(zip(needs, nodes, strict=True))}):
                return False
            nodes[:] = [child for child in nodes if child["nodes"]]
        if len(nodes) != len(wanted):
            return False
        for index, want in enumerate(wanted):
            if (not nodes[index]["nodes"]) == isinstance(want, int):
                continue
            other = next((later for later in range(index + 1, len(nodes))
                          if (not nodes[later]["nodes"]) == isinstance(want, int)), None)
            if other is not None:
                commands.append(f"[con_id={nodes[index]['id']}] swap container with con_id {nodes[other]['id']}")
                nodes[index], nodes[other] = nodes[other], nodes[index]
            elif isinstance(want, int) and len(nodes[index]["nodes"]) == 1 and not nodes[index]["nodes"][0]["nodes"]:
                unwrap(node, index)
            elif not isinstance(want, int) and len(want[1]) == 1 and want[0] not in TABBED:
                commands.append(f"[con_id={nodes[index]['id']}] split {family(want[0])}")
                nodes[index] = container(want[0], [nodes[index]])
            else:
                return False
        lines = [index for index, want in enumerate(wanted) if not isinstance(want, int) and all(isinstance(leaf, int) for leaf in want[1])
                 and all(not child["nodes"] for child in nodes[index]["nodes"])]
        if not hand_over(nodes, {index: len(wanted[index][1]) - len(nodes[index]["nodes"]) for index in lines}):
            return False
        return all(align(node, index, want) for index, want in enumerate(wanted))

    if not arrange(workspace, target[1]) or lost:
        return None
    now, want = leaves(shape(workspace)), leaves(target)
    if sorted(now) != sorted(want):
        return None
    for index, con in enumerate(want):
        if now[index] != con:
            other = now[index]
            commands += bubble(workspace, con, [other])
            now[now.index(con)], now[index] = other, con
    unnamed = any("con_id=-" in command for command in commands)
    return commands if not unnamed and trimmed(shape(workspace)) == target and not wrapped(workspace) else None


def foresee(workspace, target):
    if covered(workspace) or not workspace["nodes"]:
        return None
    parent = parent_of(target, NEXT)
    nests = [None, parent[0]] if parent is not None and len(parent[1]) == 1 else [None]
    present = tiled(workspace)
    for way in (None, *SPLITS):
        for nest in nests:
            for after in present:
                model = copied(workspace)
                put_after(model, after, NEXT)
                if way and move(model, NEXT, way) not in ("swap", "out"):
                    continue
                if nest:
                    enclose(model, NEXT, nest)
                built = shape(model)
                if (built == target if not isinstance(target, int) and target[0] not in TABBED else built[1] == [target]):
                    return after, way, nest
    return None


def conforming(layout, present):
    cons = leaves(present) if present is not None else []
    if not cons:
        return None
    logical = [0] * len(cons)
    for position, index in enumerate(leaves(trimmed(layout(list(range(len(cons))))))):
        logical[index] = cons[position]
    return logical if outline(layout(logical)) == outline(present) else None


def reorder(order, ids):
    slots, wanted = iter(ids), set(ids)
    order[:] = [next(slots) if con in wanted else con for con in order]


def placement(width, height, x, y):
    return f"resize set {width} px {height} px, move absolute position {x} px {y} px"


def resolve(tree, target):
    number = target.split()[1] if target.startswith("number ") else None
    found = [ws for ws in workspaces(tree) if (ws["num"] == int(number) if number and number.isdigit() else ws["name"] == target)]
    return found[0] if found else None


def presses(workspace, con, direction):
    model = copied(workspace)
    for count in range(1, len(ancestors(workspace, con)) + 2):
        outcome = move(model, con, direction)
        if outcome != "out":
            return count if outcome == "cross" else None
    return None


def neighbour(tree, workspace, direction):
    home = next(output for output in outputs(tree) if any(ws["id"] == workspace["id"] for ws in output["nodes"]))["rect"]
    x, y = home["x"] + home["width"] / 2, home["y"] + home["height"] / 2

    def beyond(box):
        return {"right": box["x"] >= home["x"] + home["width"], "left": box["x"] + box["width"] <= home["x"],
                "down": box["y"] >= home["y"] + home["height"], "up": box["y"] + box["height"] <= home["y"]}[direction]

    def distance(box):
        dx = max(box["x"] - x, 0, x - box["x"] - box["width"])
        dy = max(box["y"] - y, 0, y - box["y"] - box["height"])
        return dx * dx + dy * dy

    found = min((output for output in outputs(tree) if beyond(output["rect"])), key=lambda output: distance(output["rect"]), default=None)
    return next((ws for ws in found["nodes"] if ws["name"] == found.get("current_workspace")), None) if found else None


def doorway(workspace, con, direction):
    node, first = workspace, direction in ("right", "down")
    back = {"right": "left", "left": "right", "down": "up", "up": "down"}[direction]
    while node["nodes"] and family(node["layout"]) != family(SPLITS[direction]):
        parent, node = node, next((child for id in node["focus"] for child in node["nodes"] if child["id"] == id), node["nodes"][0])
        if not node["nodes"]:
            way = {"h": "left", "v": "up"}[family(parent["layout"])]
            return after(node["id"], con) + ([f"[con_id={con}] move {way}"] if first else [])
    if not node["nodes"]:
        return None
    end, model = node, copied(workspace)
    while end["nodes"]:
        end = end["nodes"][0 if first else -1]
    put_after(model, end["id"], con)
    steps = after(end["id"], con)
    while True:
        parent = ancestors(model, con)[-2]
        if parent["id"] == node["id"] and parent["nodes"][0 if first else -1]["id"] == con:
            return steps
        if move(model, con, back) not in ("swap", "out") or len(steps) > 20:
            return None
        steps.append(f"[con_id={con}] move {back}")


def facing(node, direction):
    if isinstance(node, int):
        return [node]
    if node[0] == SPLITS[direction]:
        return facing(node[1][0 if direction in ("right", "down") else -1], direction)
    return [leaf for child in node[1] for leaf in facing(child, direction)]


def path(node, leaf):
    if node == leaf:
        return []
    if isinstance(node, int):
        return None
    return next(([index, *rest] for index, child in enumerate(node[1]) if (rest := path(child, leaf)) is not None), None)


def last_focused(node):
    while node["nodes"]:
        node = next((child for id in node["focus"] for child in node["nodes"] if child["id"] == id), node["nodes"][0])
    return node["id"]


def areas(node, master=None, share=None, x=0.0, y=0.0, width=1.0, height=1.0):
    if isinstance(node, int):
        return {node: (x, y, width, height)}
    layout, children = node
    if layout in TABBED:
        return {leaf: box for child in children for leaf, box in areas(child, master, share, x, y, width, height).items()}
    across = layout == "splith"
    room = width if across else height
    sizes = [room / len(children)] * len(children)
    if share is not None and master in children and len(children) > 1:
        sizes = [room * share if child == master else room * (1 - share) / (len(children) - 1) for child in children]
    found, offset = {}, 0.0
    for child, size in zip(children, sizes, strict=True):
        found.update(areas(child, master, share, *((x + offset, y, size, height) if across else (x, y + offset, width, size))))
        offset += size
    return found


def overlap(first, second):
    width = min(first[0] + first[2], second[0] + second[2]) - max(first[0], second[0])
    height = min(first[1] + first[3], second[1] + second[3]) - max(first[1], second[1])
    return max(0.0, width) * max(0.0, height)


def known(value, choices, default):
    return value if isinstance(value, str) and value in choices else default


def load_state():
    try:
        saved = json.loads(STATE.read_text())
    except (OSError, ValueError):
        saved = {}
    saved = saved if isinstance(saved, dict) else {}
    chosen = saved.get("workspaces") if isinstance(saved.get("workspaces"), dict) else {}
    return {"layout": known(saved.get("layout"), LAYOUTS, "master"), "new": known(saved.get("new"), NEW, "stack"),
            "workspaces": {name: known(layout, LAYOUTS, None) for name, layout in chosen.items() if known(layout, LAYOUTS, None)}}


def save_state(state, path=None):
    path = path or STATE
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f".{path.name}.{os.getpid()}")
    temporary.write_text(json.dumps(state))
    os.replace(temporary, path)


def runtime_path(sway, suffix):
    runtime = Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}")
    return runtime / f"swaytiles.{Path(sway.path).name}.{suffix}"


def frozen(node):
    if isinstance(node, int) and not isinstance(node, bool):
        return node
    valid = isinstance(node, list) and len(node) == 2 and node[0] in (*TABBED, *SPLITS.values()) and isinstance(node[1], list)
    children = [frozen(child) for child in node[1]] if valid else [None]
    return (node[0], children) if None not in children else None


def load_session(path):
    try:
        saved = json.loads(path.read_text())
    except (OSError, ValueError):
        saved = {}
    saved = saved if isinstance(saved, dict) else {}
    built = saved.get("built")
    built = {name: tree for name, tree in ((name, frozen(tree)) for name, tree in (built.items() if isinstance(built, dict) else ()))
             if tree is not None}
    return built


def keep(table, name, value, even, exact=False):
    value, saved = round(value, 2), table.get(name)
    if saved is not None and abs(value - saved) < (0.01 if exact else 0.02):
        return
    if abs(value - even) < 0.02:
        table.pop(name, None)
    else:
        table[name] = value


class Daemon:
    def __init__(self, sway, keys=True):
        self.sway = sway
        self.keys = keys
        self.adopted = {}
        self.state = load_state()
        self.order = []
        self.anchored = {}
        self.ringed = set()
        self.closing = {}
        self.token = os.urandom(4).hex()
        self.where = {}
        self.seen = None
        self.heir = None
        self.gone = {}
        self.names = {}
        self.tiled = set()
        self.ratios = {}
        self.leans = {}
        self.gaps = {}
        self.sized = {}
        self.roles = {}
        self.resizing = {}
        self.foreseen = {}
        self.watching = 0.0
        self.carried = (None, None)
        self.session = runtime_path(sway, "json")
        self.built = load_session(self.session)
        self.saved = self.remembered()
        self.sync_id = 0
        self.syncing = None

    def remembered(self):
        return {"built": dict(self.built)}

    def remember(self):
        now = self.remembered()
        if now != self.saved:
            save_state(now, self.session)
            self.saved = now

    def chosen(self, name):
        return self.state["workspaces"].get(name)

    def tiling(self, name):
        return LAYOUTS.get(self.chosen(name))

    def ordered(self, cons):
        cons = set(cons)
        return [con for con in self.order if con in cons]

    def target(self, name, ids):
        return trimmed(self.tiling(name)(ids)) if ids else None

    def inspect(self, workspace, ids, arrived, opened=()):
        name, seen = workspace["name"], self.built.get(workspace["name"])
        if trimmed(shape(workspace)) == self.target(name, ids):
            return
        if seen is not None:
            had = set(leaves(seen))
            if self.leads(name) and any(con in opened for con in ids):
                return
            present = without(shape(workspace), *(con for con in ids if con not in had))
            before = without(seen, *had.difference(ids))
            if outline(before) != outline(present):
                return self.adapt(workspace, present, bare(trimmed(before)) == bare(trimmed(present)))
        if arrived in ids and (found := conforming(self.tiling(name), shape(workspace))):
            reorder(self.order, found)

    def adapt(self, workspace, present, restyled):
        name = workspace["name"]
        candidates = [(self.chosen(name), self.tiling(name))]
        if restyled:
            candidates += [(other, layout) for other, layout in LAYOUTS.items() if layout and other != self.chosen(name)]
        kept = self.ordered(leaves(present))
        for other, layout in candidates:
            found = conforming(layout, present)
            if found and (other == self.chosen(name) or found == kept):
                reorder(self.order, found)
                if other != self.chosen(name):
                    self.state["workspaces"][name] = other
                    save_state(self.state)
                return
        print(f"swaytiles: Workspace {name} lost its layout after a manual change. Switching to master.", file=sys.stderr)
        self.state["workspaces"][name] = "master"
        save_state(self.state)
        self.built.pop(name, None)

    def measure(self, workspace, ids, new=None, exact=False):
        name, node = workspace["name"], top(workspace)
        others = [child for child in node["nodes"] if tiled(child) != [new]]
        master = next((child for child in others if child["id"] == ids[0]), None)
        if node["layout"] in ("splith", "splitv") and len(others) > 1 and master is not None:
            axis = extent(node["layout"])
            room = node["rect"][axis] - sum(span(child, axis) for child in node["nodes"] if tiled(child) == [new])
            keep(self.ratios, name, span(master, axis) / room, 1 / len(others), exact)
            self.gaps[name] = gap(workspace, axis)
            if len(others) == 3 and others[1] is master:
                first, last = (span(side, axis) for side in (others[0], others[2]))
                keep(self.leans, name, first / (first + last), 0.5, exact)

    def measure_gone(self, workspace, ids, gone):
        name, node = workspace["name"], top(workspace)
        master = next((child for child in node["nodes"] if child["id"] == ids[0]), None)
        if node["layout"] not in ("splith", "splitv") or master is None or ids[0] not in branches(self.built.get(name)):
            return
        axis = extent(node["layout"])
        now = sum(span(child, axis) for child in node["nodes"])
        before = now - (gap(workspace, axis) if len(node["nodes"]) > 1 else self.gaps.get(name, 0))
        was = span(master, axis) / now * (before - span(gone, axis))
        keep(self.ratios, name, was / node["rect"][axis], 1 / (len(node["nodes"]) + 1), exact=True)

    def farewell(self, node, workspace):
        name = self.where.get(node["id"])
        built = self.built.get(name)
        if workspace is None or len(branches(built)) < 2 or node["id"] not in built[1] or built[0] not in ("splith", "splitv"):
            return
        if next((con for con in self.order if con in leaves(built)), None) == node["id"]:
            axis = extent(built[0])
            keep(self.ratios, name, span(node, axis) / workspace["rect"][axis], 1 / len(built[1]))

    def measure_all(self, tree, exact=False):
        for workspace in workspaces(tree):
            name = workspace["name"]
            if self.tiling(name) is None or covered(workspace):
                continue
            ids = self.ordered(tiled(workspace))
            if ids and trimmed(shape(workspace)) == self.target(name, ids):
                self.measure(workspace, ids, exact=exact)

    def remeasure(self, tree):
        before = dict(self.ratios), dict(self.leans)
        self.measure_all(tree)
        if (self.ratios, self.leans) != before:
            self.sway.command(*self.anchors(tree))

    def sizing(self, name, target, ids):
        ratio = self.ratios.get(name)
        if ratio is None or ids[0] not in branches(target) or target[0] not in ("splith", "splitv"):
            return None
        return extent(target[0]), round(ratio * 100)

    def resize(self, name, target, ids, workspace, settled=False):
        size = self.sizing(name, target, ids)
        if not size:
            return []
        command = f"[con_id={ids[0]}] resize set {size[0]} {size[1]} ppt"
        lean = self.leans.get(name, 0.5)
        if not settled:
            middle = len(target[1]) == 3 and target[1][1] == ids[0]
            return balancing(workspace, ids[0], (leaves(target[1][0])[0], leaves(target[1][2])[0]), *size, lean) if middle else [command]
        if (sides := flanks(workspace, ids[0])) is not None:
            master = top(workspace)["nodes"][1]
            wanted = (*sides_room(workspace, size[0], size[1], lean), workspace["rect"][size[0]] * size[1] // 100)
            close = max(2, workspace["rect"][size[0]] // 100)
            if all(abs(span(node, size[0]) - room) <= close for node, room in zip((*sides, master), wanted, strict=True)):
                return []
            return balancing(workspace, ids[0], tuple(tiled(side)[0] for side in sides), *size, lean)
        node = top(workspace)
        master = next((child for child in node["nodes"] if child["id"] == ids[0]), None)
        if master is not None and abs(span(master, size[0]) / node["rect"][size[0]] - size[1] / 100) < 0.01:
            return []
        return [command]

    def taker(self, name, ids, con, rect, area):
        rest = [other for other in ids if other != con]
        if con not in ids or not rest:
            return None
        target = self.target(name, rest)
        size = self.sizing(name, target, rest)
        places = areas(target, rest[0], size[1] / 100 if size else None)
        was = ((rect["x"] - area["x"]) / area["width"], (rect["y"] - area["y"]) / area["height"],
               rect["width"] / area["width"], rect["height"] / area["height"])
        nearest = rest[min(ids.index(con), len(rest) - 1)]
        return max(rest, key=lambda other: (round(overlap(places.get(other, (0, 0, 0, 0)), was), 4), other == nearest))

    def entry(self, name, ws, coming, master, axis, share):
        node = top(ws)
        children = coming[1]
        if len(children) != 3 or children[1] != master or [NEXT] not in (leaves(children[0]), leaves(children[2])) or len(node["nodes"]) != 2:
            return 0
        present = sum(span(child, axis) for child in node["nodes"])
        side = next(child for child in node["nodes"] if child["id"] != master)
        room = 2 * present - node["rect"][axis]
        if room <= 0:
            return 0
        lean = self.leans.get(name, 0.5)
        lean = lean if leaves(children[0]) == [NEXT] else 1 - lean
        kept, taken = 2 / 3 * span(side, axis) / present, node["rect"][axis] * share // 100 / room
        return round(((2 * lean - 1) * (1 - taken) + kept + 1 / 6) / 1.5 * room)

    def insist(self, command):
        for delay in (0.3, 1.0):
            threading.Timer(delay, self.sway.command, [command]).start()

    def sync(self):
        self.sync_id += 1
        self.sway.tick(f"{SYNC} {self.sync_id}")
        self.syncing = self.sync_id

    def tile_rule(self, name, active):
        if self.anchored.get(name) == active or (not active and name not in self.anchored):
            return []
        code = encoded(name)
        variable = f"$layout_tile_{code}"
        commands = [] if self.anchored else ["set $layout_gate _layout_off", 'for_window [all] "mark --add $$layout_gate; unmark $$layout_gate"',
                                             "[all] mark --add _layout_arm", "unmark _layout_arm", "set $layout_gate _layout_fresh"]
        commands.append(f"set {variable} {AFTER + code if active else '_layout_off'}")
        role, way, inner, lead = f"$layout_role_{code}", f"$layout_way_{code}", f"$layout_inner_{code}", f"$layout_lead_{code}"
        if not active:
            commands += [f"set {role} _layout_none_{code}", f"set {lead} _layout_none_{code}"]
            self.roles.pop(name, None)
        if name not in self.anchored:
            axis, share = f"$layout_axis_{code}", f"$layout_share_{code}"
            entry = f"$layout_entry_{code}"
            commands += [f"set {axis} width", f"set {share} 50", f"set {entry} 0", f"set {role} _layout_none_{code}", f"set {way} right", f"set {inner} splith",
                         f"set {lead} _layout_none_{code}"]
            fresh = "[con_mark=^_layout_fresh$]"
            action = (f"[con_mark=^{AFTER + code}$ workspace={elsewhere(name)}] unmark {AFTER + code}",
                      f"{fresh} move container to mark ${variable}", f"{fresh} mark --add ${variable}",
                      f"{fresh} mark --add ${role}",
                      f"[con_mark=^_layout_(turn|both)_{code}$] move ${way}",
                      f"[con_mark=^_layout_(nest|both)_{code}$] split h, layout ${inner}",
                      f"{fresh} unmark ${role}", f"{fresh} set ${role} _layout_none_{code}",
                      f"{fresh} resize set ${axis} ${entry} px",
                      f"[con_mark=^{SIZED + code}$] resize set ${axis} ${share} ppt",
                      f"{fresh} set ${entry} 0", f"{fresh} set ${share} 0",
                      f"{fresh} mark --add ${lead}", f"{fresh} unmark ${lead}", f"{fresh} set ${lead} _layout_none_{code}",
                      "[con_mark=^_layout_off$] unmark _layout_off")
            commands.append(f'for_window [workspace="^{criteria(name)}$" tiling] "{"; ".join(action)}"')
        self.anchored[name] = active
        return commands

    def ring_rule(self, name, size):
        if (name, size) in self.ringed:
            return []
        self.ringed.add((name, size))
        code = encoded(name)
        action = [f"[con_mark=^{RING}{index}_{code}$ workspace=^{loosely(name)}$] swap container with mark _layout_fresh" for index in reversed(range(size))]
        return [f'for_window [workspace="^{criteria(name)}$" tiling con_mark="^{self.lead(code, size)}$"] "{"; ".join(action)}"']

    def lead(self, code, size):
        return f"_layout_lead{size}_{code}_{self.token}"

    def anchors(self, tree):
        held = marked(tree, PLACING)
        wanted, commands = {}, []
        for ws in workspaces(tree):
            name = ws["name"]
            active = self.chosen(name) is not None
            commands += self.tile_rule(name, active)
            ids = self.ordered(tiled(ws))
            self.resizing[name] = False
            if active and ids:
                commands += self.prepare(ws, name, ids, wanted)
            elif active:
                commands += self.step(name)
        commands += [f"unmark {mark}" for mark in held if mark not in wanted]
        return commands + [f"[con_id={con}] mark --add {mark}" for mark, con in wanted.items() if held.get(mark) != con]

    def step(self, name, way=None, nest=None, ring=0):
        code = encoded(name)
        role = "both" if way and nest else "turn" if way else "nest" if nest else "none"
        values = (f"_layout_{role}_{code}", way or "right", layout_command(nest)[7:] if nest else "splith",
                  self.lead(code, ring) if ring else f"_layout_none_{code}")
        if self.roles.get(name) == values:
            return []
        self.roles[name] = values
        keys = ("layout_role", "layout_way", "layout_inner", "layout_lead")
        return [f"set ${key}_{code} {value}" for key, value in zip(keys, values, strict=True)]

    def leads(self, name):
        return self.state["new"] == "master" and self.chosen(name) in LEADING

    def welcome(self, tree, con):
        workspace = next((ws for ws in workspaces(tree) if con in tiled(ws)), None)
        ids = self.ordered(tiled(workspace)) if workspace is not None and self.leads(workspace["name"]) else []
        return self.order.index(ids[0]) if ids else len(self.order)

    def prepare(self, ws, name, ids, wanted):
        leading = self.leads(name)
        code, now, coming = encoded(name), self.target(name, ids), self.target(name, [*ids, NEXT])
        commands, planned, ring = [], None, 0
        if len(ids) == 1 and ws["nodes"] and ws["nodes"][0]["id"] == ids[0] and coming[0] not in TABBED and ws["layout"] != coming[0]:
            commands += [f"[con_id={ids[0]}] move {direction}" for direction in turns(ws["layout"], coming[0])]
            ws = {**ws, "layout": coming[0]}
        if not covered(ws):
            choices = [([ids[0], NEXT, *ids[1:]], 1), ([*ids, NEXT], len(ids))] if leading else [([*ids, NEXT], 0)]
            for order, size in choices:
                coming = self.target(name, order)
                if planned := self.plan(ws, name, coming):
                    ring = size
                    break
        anchor, way, nest = planned or (ids[-1], None, None)
        wanted[AFTER + code] = anchor
        wanted.update({f"{RING}{index}_{code}": con for index, con in enumerate(ids[:ring])})
        commands += [*(self.ring_rule(name, ring) if ring else []), *self.step(name, way, nest, ring)]
        level = 1 if isinstance(now, int) or now[0] in TABBED else len(now[1])
        widening = not isinstance(coming, int) and len(coming[1]) > level
        size = self.sizing(name, coming, [*ids, NEXT]) if widening else None
        self.resizing[name] = bool(size)
        entry = self.entry(name, ws, coming, ids[0], *size) if size else 0
        if size and self.sized.get(name, (None, None))[0] != size:
            commands += [f"set $layout_axis_{code} {size[0]}", f"set $layout_share_{code} {size[1]}"]
        if entry != self.sized.get(name, (None, None))[1]:
            commands.append(f"set $layout_entry_{code} {entry}")
        self.sized[name] = (size if size else self.sized.get(name, (None, 0))[0], entry)
        if size:
            wanted[SIZED + code] = ids[0]
        return commands

    def plan(self, workspace, name, target):
        key = (workspace["layout"], shape(workspace))
        if self.foreseen.get(name, (None,))[0] != key:
            self.foreseen[name] = (key, [])
        plans = self.foreseen[name][1]
        for wanted, found in plans:
            if wanted == target:
                return found
        plans.append((target, foresee(workspace, target)))
        return plans[-1][1]

    def placed(self, tree, new, moved):
        where = {node["id"]: ws["name"] for ws in workspaces(tree) for node in windows(ws)}
        local = moved and new in where and self.where.get(new) == where[new]
        (carried, name), self.carried = self.carried, (None, None)
        landed = new == carried and where.get(carried) == name and self.where.get(carried) != name
        self.where = where
        self.names = {ws["id"]: ws["name"] for ws in workspaces(tree)}
        if local and self.syncing is not None:
            return True, None
        if not moved or local or landed:
            return False, None
        if new in self.order:
            self.order.remove(new)
            self.order.append(new)
        return False, new

    def shape_up(self, workspace, ids, new, focused, regrouped):
        name = workspace["name"]
        target = self.target(name, ids)
        if target is None:
            return False
        if target == trimmed(shape(workspace)) and not wrapped(workspace):
            sized = self.resize(name, target, ids, workspace, settled=True) if new in ids or regrouped else []
            self.sway.command(*sized)
            return bool(sized)
        model = copied(workspace)
        steps = reconcile(model, target)
        if steps is not None:
            moved = {child["id"] for child in top(model)["nodes"]} != {child["id"] for child in top(workspace)["nodes"]}
            sized = self.resize(name, target, ids, workspace) if moved or regrouped else []
            self.sway.command(*steps, *([refocus(focused)] if focused in ids and steps else []), *sized)
            return bool(steps or sized)
        self.sway.command(*(assemble(workspace, target, focused) or []), *self.resize(name, target, ids, workspace))
        return True

    def regrouped(self, workspace):
        return len(top(workspace)["nodes"]) < len(branches(self.built.get(workspace["name"])))

    def arrange(self, new=None, moved=False, tree=None):
        heir, self.heir = self.heir, None
        gone, self.gone = self.gone, {}
        tree = tree or self.sway.tree()
        unseen = [ws["name"] for ws in workspaces(tree) if ws["name"] not in self.state["workspaces"]]
        if unseen:
            self.state["workspaces"].update(dict.fromkeys(unseen, self.state["layout"]))
            save_state(self.state)
        skip, arrived = self.placed(tree, new, moved)
        if skip:
            return self.remember()

        tiles = {ws["id"]: tiled(ws) for ws in workspaces(tree)}
        present = {node["id"] for ws in workspaces(tree) for node in windows(ws)}
        self.tiled = (self.tiled & present) | {con for ids in tiles.values() for con in ids}
        self.order[:] = [con for con in self.order if con in self.tiled]
        unseen = [con for ids in tiles.values() for con in ids if con not in self.order]

        opened = sorted(con for con in unseen if self.seen is not None and con not in self.seen)
        self.order += [con for con in unseen if con not in opened]
        for con in opened:
            self.order.insert(self.welcome(tree, con), con)
        if self.seen is None:
            for workspace in workspaces(tree):
                if not covered(workspace) and self.tiling(workspace["name"]) is not None and tiles[workspace["id"]]:
                    reorder(self.order, conforming(self.tiling(workspace["name"]), shape(workspace)) or [])
        self.seen = everyone(tree)

        for workspace in workspaces(tree):
            if not covered(workspace) and self.tiling(workspace["name"]) is not None and (ids := self.ordered(tiles[workspace["id"]])):
                self.inspect(workspace, ids, arrived, opened)
        heir = heir if heir in present else None
        focused, onscreen, shaped = heir or focused_node(tree)["id"], visible(tree), False

        for workspace in workspaces(tree):
            name = workspace["name"]
            ids = self.ordered(tiles[workspace["id"]])
            if covered(workspace):
                continue
            if self.tiling(name) is not None and ids:
                tree_shape = shape(workspace)
                regrouped = self.regrouped(workspace)
                if regrouped and name in gone:
                    self.measure_gone(workspace, ids, gone[name])
                resized = (new in ids and self.resizing.get(name)) or regrouped
                seen = self.built.get(name)
                left = name in gone and ids[0] in branches(seen) and trimmed(tree_shape) == trimmed(without(seen, new))
                if not resized and (trimmed(tree_shape) == self.target(name, ids) or left or trimmed(without(tree_shape, new)) == seen):
                    self.measure(workspace, ids, new, exact=name in gone)
                shaped = self.shape_up(workspace, ids, new, focused, regrouped) or shaped
        tree = self.sway.tree() if shaped else tree
        handover = [refocus(heir)] if heir is not None and focused_node(tree)["id"] != heir else []
        self.sway.command(*handover, *self.anchors(tree))
        self.record(tree)
        self.remember()
        if shaped:
            self.sync()

    def record(self, tree):
        for workspace in workspaces(tree):
            name = workspace["name"]
            if self.tiling(name) is None or not tiled(workspace):
                self.built.pop(name, None)
            elif not covered(workspace):
                self.built[name] = trimmed(shape(workspace))

    def move_to(self, target=None, direction=None):
        tree = self.sway.tree()
        node, source = focused_window(tree)
        native = f"move container to workspace {target}" if target else f"move {direction}"
        if source is None or node["nodes"]:
            return self.sway.command(native)
        con = node["id"]
        managed = node["type"] == "con" and self.tiling(source["name"]) is not None and not covered(source)
        count = direction and node["type"] == "con" and presses(source, con, direction)
        if direction and managed:
            other = beside(source, node, direction, self.order)
            if other is not None:
                if con in self.order and other in self.order:
                    first, second = self.order.index(con), self.order.index(other)
                    self.order[first], self.order[second] = other, con
                self.sway.command(f"[con_id={con}] swap container with con_id {other}")
                self.sync()
                return self.arrange()
            destination = neighbour(tree, source, direction)
            if destination is None:
                return None
        elif direction:
            destination = neighbour(tree, source, direction) if count else None
        else:
            destination = resolve(tree, target)
        if destination is None or destination["id"] == source["id"]:
            return self.sway.command(f"[con_id={con}] {native}")
        name = destination["name"]
        before, away = self.leaving(source, node, focus=bool(target))
        steps = self.entering(destination, con, direction)
        self.carried = (con, name)
        command = native if target else f"move container to workspace {quoted(name)}, focus"
        if steps and node["type"] == "con":
            self.sway.command(*before, *steps, *away, *([f"[con_id={con}] focus"] if direction else []))
            self.record(self.sway.tree())
        elif managed and direction and not covered(destination) and (entry := doorway(destination, con, direction)):
            self.sway.command(*before, *entry, *away, f"[con_id={con}] focus")
        else:
            self.sway.command(*before, f"[con_id={con}] " + (", ".join([native] * count) if count and not managed else command), *away)

    def entering(self, workspace, con, heading=None):
        name = workspace["name"]
        ids = [other for other in self.ordered(tiled(workspace)) if other != con]
        layout = self.tiling(name)
        near = heading in ("right", "down")

        def built(place):
            return normalize(layout([*ids[:place], con, *ids[place:]]))
        edge = [place for place in range(len(ids) + 1) if con in facing(built(place), heading)] if ids and heading and layout else []
        at = (min if near else max)(edge, default=len(ids))
        along = heading and family(SPLITS[heading])
        holders = lineage(built(edge[0]), con) if edge else []
        outer = [holder[0] for holder in holders] + (["splith"] if holders and holders[0][0] in TABBED else [])
        if edge and not (holders[-1][0] in TABBED and along in map(family, outer)):
            now = normalize(layout(ids))
            focus = path(now, last_focused(workspace)) or []
            shared = {leaf: len(os.path.commonprefix([path(now, leaf), focus])) for leaf in facing(now, heading)}
            by = max(shared, key=lambda leaf: (shared[leaf], -ids.index(leaf) if near else ids.index(leaf)))
            if shared[by]:
                want = ids.index(by) + (not near)
                if (titles := parent_of(now, by))[0] in TABBED and family(titles[0]) == along:
                    want = ids.index(leaves(titles)[0]) if near else ids.index(leaves(titles)[-1]) + 1
                at = min(edge, key=lambda place: (abs(place - want), place if near else -place))
        self.order[:] = [other for other in self.order if other != con]
        self.order.insert(self.order.index(ids[at]) if at < len(ids) else len(self.order), con)
        if not ids or layout is None or covered(workspace):
            return []
        order = [*ids[:at], con, *ids[at:]]
        target = self.target(name, order)
        arrival = self.arrival(workspace, name, ids, con, at, target)
        if arrival is None:
            model = copied(workspace)
            put_after(model, ids[-1], con)
            return after(ids[-1], con) + (assemble(model, target, con) or []) + self.resize(name, target, order, workspace)
        steps, model = arrival
        widened = len(top(model)["nodes"]) > len(top(workspace)["nodes"])
        return steps + (self.resize(name, target, order, workspace) if widened else [])

    def arrival(self, workspace, name, ids, con, at, target):
        plan = self.plan(workspace, name, self.target(name, [*ids, NEXT]))
        if plan is None:
            return None
        anchor, way, nest = plan
        model, steps = copied(workspace), after(anchor, con)
        put_after(model, anchor, con)
        if way:
            move(model, con, way)
            steps.append(f"[con_id={con}] move {way}")
        if nest:
            enclose(model, con, nest)
            steps.append(f"[con_id={con}] split h, {layout_command(nest)}")
        steps += bubble(model, con, ids[at:][::-1])
        return (steps, model) if trimmed(shape(model)) == target else None

    def leaving(self, workspace, node, focus=False):
        name, con = workspace["name"], node["id"]
        order = self.ordered(tiled(workspace))
        ids = [other for other in order if other != con]
        if node["type"] != "con" or self.tiling(name) is None or not ids or covered(workspace):
            return [], []
        self.farewell(node, workspace)
        rest, target = copied(workspace), self.target(name, ids)
        take_out(rest, con)
        handover = [f"[con_id={self.taker(name, order, con, node['rect'], workspace['rect'])}] focus"] if focus else []

        def sized(model):
            return self.resize(name, target, ids, workspace) if len(top(model)["nodes"]) < len(top(workspace)["nodes"]) else []
        if trimmed(shape(rest)) == target and not wrapped(rest):
            return [], sized(rest) + handover
        model = copied(workspace)
        before = bubble(model, con, order[order.index(con) + 1:])
        take_out(model, con)
        steps = reconcile(model, target)
        if steps is None:
            return [], (assemble(rest, target) or []) + self.resize(name, target, ids, workspace) + handover
        return before, steps + sized(model) + handover

    def switch(self, mode):
        tree = self.sway.tree()
        node, source = focused_window(tree)
        native = "move scratchpad" if mode == "scratchpad" else f"floating {mode}"
        floating = node["type"] == "floating_con"
        joins = floating and mode in ("toggle", "disable")
        quits = not floating and mode in ("toggle", "enable", "scratchpad")
        if source is None or node["nodes"] or not (joins or quits):
            return self.sway.command(native)
        con = node["id"]
        if joins:
            self.sway.command(f"[con_id={con}] floating disable", *self.entering(source, con))
        else:
            before, after = self.leaving(source, node, focus=mode == "scratchpad")
            self.sway.command(*before, f"[con_id={con}] {'floating enable' if mode != 'scratchpad' else native}", *after)
        return self.sync()

    def close(self):
        tree = self.sway.tree()
        node, source = focused_window(tree)
        if source is None or node["nodes"] or node["type"] != "con" or self.tiling(source["name"]) is None:
            return self.sway.command("kill")
        self.measure_all(tree, exact=True)
        con, rest = node["id"], copied(source)
        take_out(rest, con)
        ids = [other for other in self.ordered(tiled(source)) if other != con]
        if not ids or covered(source):
            return self.sway.command("kill")
        target = self.target(source["name"], ids)
        regrouped = self.sizing(source["name"], target, ids) and len(top(rest)["nodes"]) < len(top(source)["nodes"])
        if trimmed(shape(rest)) == target and not regrouped:
            return self.sway.command("kill")
        before, after = self.leaving(source, node, focus=True)
        rect = node["rect"]
        self.closing[con] = f"border {node['border']} {node['current_border_width']}" if node["border"] != "none" else "border none"
        cover = f"[con_id={con}] floating enable, {self.closing[con]}, {placement(rect['width'], rect['height'], rect['x'], rect['y'])}"
        self.sway.command(*before, cover, *after, f"[con_id={con}] kill")
        threading.Timer(CLOSING, self.sway.tick, [f"{ACT} back {con}"]).start()
        return self.sync()

    def back(self, con):
        border = self.closing.pop(con, None)
        tree = self.sway.tree()
        workspace = next((ws for ws in workspaces(tree) if any(node["id"] == con for node in ws["floating_nodes"])), None)
        if border is None or workspace is None:
            return None
        entering = self.entering(workspace, con) if self.tiling(workspace["name"]) is not None else []
        self.sway.command(f"[con_id={con}] floating disable, {border}", *entering, f"[con_id={con}] focus")
        return self.sync()

    def unhide(self, con=None):
        tree = self.sway.tree()
        hidden = [node["id"] for output in tree["nodes"] if output["name"] == "__i3" for ws in output["nodes"] for node in ws["floating_nodes"]]
        if con is None and hidden:
            con = hidden[-1]
        if con not in hidden:
            return None
        name = self.sway.focused_workspace()
        workspace = named(tree, name)
        commands = [f"[con_id={con}] scratchpad show", f"[con_id={con}] floating disable", *self.entering(workspace, con)]
        self.where[con] = name
        self.sway.command(*commands, f"[con_id={con}] focus")
        self.record(self.sway.tree())
        self.remember()
        return self.sync()

    def choose(self, choice):
        self.measure_all(self.sway.tree())
        name = self.sway.focused_workspace()
        self.state["workspaces"][name] = choice
        save_state(self.state)
        self.built.pop(name, None)
        self.arrange()

    def rename(self, workspace):
        old, new = self.names.get(workspace["id"]), workspace["name"]
        if old is None or old == new:
            return
        for table in (self.state["workspaces"], self.ratios, self.leans, self.gaps, self.built):
            if old in table and new not in table:
                table[new] = table.pop(old)
        save_state(self.state)

    def restore(self, sway):
        tree = sway.tree()
        commands = [command for name in list(self.anchored) for command in self.tile_rule(name, False)]
        sway.command(*commands, *(f"[con_id={con}] opacity 1" for con in invisible(tree)), *(f"unmark {mark}" for mark in marked(tree, PLACING)))

    def recover(self):
        self.sway.command(*(f"[con_id={con}] opacity 1" for con in invisible(self.sway.tree())))

    def pause(self):
        left = self.watching - time.monotonic()
        return min(WATCH[0], left) if left > 0 else None

    def drifted(self, tree):
        return any(self.tiling(ws["name"]) is not None and ws["name"] in self.built and not covered(ws)
                   and trimmed(shape(ws)) != self.built[ws["name"]] for ws in workspaces(tree))

    def handle(self, kind, event):
        change = event.get("change")
        if kind == "idle":
            if self.drifted(tree := self.sway.tree()):
                self.watching = 0.0
                self.arrange(tree=tree)
            else:
                self.remeasure(tree)
        elif kind == "tick":
            payload = event.get("payload", "")
            if payload == f"{SYNC} {self.syncing}":
                self.syncing = None
            elif payload.startswith("layout ") and payload[7:] in LAYOUTS:
                self.choose(payload[7:])
            elif payload.startswith(f"{ACT} "):
                self.act(payload[len(ACT) + 1:])
        elif kind == "binding":
            command = event["binding"].get("command", "")
            if command.startswith("nop layout "):
                self.act(command[11:])
            elif RESHAPING.search(command):
                self.arrange()
            elif following(command):
                self.learn(event["binding"], command)
                self.remeasure(self.sway.tree())
            elif self.drifted(tree := self.sway.tree()):
                self.arrange(tree=tree)
            else:
                self.remeasure(tree)
        elif kind == "output":
            self.arrange()
        elif kind == "workspace" and change in ("init", "move", "rename", "reload"):
            if change == "rename":
                self.rename(event["current"])
            if change == "reload":
                for table in (self.anchored, self.ringed, self.sized, self.roles, self.adopted):
                    table.clear()
                self.adopt()
            self.arrange()
        elif kind == "window" and change == "focus":
            self.watching = time.monotonic() + WATCH[1]
        elif kind == "window" and change == "fullscreen_mode":
            self.arrange()
        elif kind == "window" and change in ("new", "close", "floating", "move"):
            con = event["container"]["id"]
            name, tree = self.where.get(con), None
            if change == "close":
                self.closing.pop(con, None)
            if change == "close" and self.tiling(name) is not None:
                tree = self.sway.tree()
                workspace = named(tree, name)
                self.farewell(event["container"], workspace)
                self.gone[name] = event["container"]
                if event["container"].get("focused") and workspace is not None:
                    built = self.built.get(name)
                    ids = self.ordered(leaves(built)) if built is not None else []
                    self.heir = self.taker(name, ids, con, event["container"]["rect"], workspace["rect"])
            if change == "new":
                self.roles.clear()
                self.sized.clear()
                self.sync()
            self.arrange(con, moved=change == "move", tree=tree)

    def adopt(self):
        self.give_back(self.sway)
        if not self.keys:
            return
        latest = {}
        with contextlib.suppress(OSError, KeyError, TypeError, ValueError):
            path = config_path(self.sway.path)
            for prefix, command in bindings(self.sway.request(Sway.CONFIG)["config"], path.parent if path else Path.home()):
                latest[same_keys(prefix)] = (prefix, command)
        self.adopted = {keys: binding for keys, binding in latest.items() if following(binding[1])}
        self.sway.command(*(f"{prefix} {following(command)}" for prefix, command in self.adopted.values()))

    def learn(self, binding, command):
        if not self.keys or binding.get("input_type") != "keyboard" or not binding.get("symbol"):
            return
        prefix = "bindsym " + "+".join([*binding.get("event_state_mask", []), binding["symbol"]])
        if same_keys(prefix) in self.adopted or self.sway.request(Sway.MODE).get("name") != "default":
            return
        self.adopted[same_keys(prefix)] = (prefix, command)
        self.sway.command(f"{prefix} {following(command)}")

    def give_back(self, sway):
        adopted, self.adopted = self.adopted, {}
        sway.command(*(f"{prefix} {command}" for prefix, command in adopted.values()))

    def act(self, action):
        if action == "hide":
            self.switch("scratchpad")
        elif action == "close":
            self.close()
        elif action.startswith("float ") and action[6:] in ("toggle", "enable", "disable"):
            self.switch(action[6:])
        elif action.startswith("back ") and action[5:].isdigit():
            self.back(int(action[5:]))
        elif action == "show" or (action.startswith("show ") and action[5:].isdigit()):
            self.unhide(int(action[5:]) if action[5:] else None)
        elif action.startswith("move ") and action[5:].strip():
            argument = action[5:].strip()
            self.move_to(direction=argument) if argument in SPLITS else self.move_to(target=argument)

    def run(self):
        events = self.sway.subscribe(SUBSCRIPTIONS, self.pause)
        self.restore(self.sway)
        self.adopt()
        self.arrange()
        for kind, event in events:
            if kind == "shutdown":
                return False
            try:
                self.handle(kind, event)
            except ConnectionError:
                raise
            except Exception:
                import traceback
                traceback.print_exc(file=sys.stderr)
                sys.stderr.flush()
                self.recover()
        return False


def claim(sway):
    lock = open(runtime_path(sway, "lock"), "w")
    for _ in range(50):
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return lock
        except BlockingIOError:
            time.sleep(0.1)
    lock.close()
    return None


def stop(*_):
    raise SystemExit(0)


def running():
    for path in (os.environ.get("SWAYSOCK"), discover()):
        if path:
            with contextlib.suppress(OSError), socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as probe:
                probe.settimeout(2)
                probe.connect(path)
                return path
    return None


def wait(keys=True):
    while True:
        path = running()
        if path and main(keys, path) == 2:
            return 2
        time.sleep(1)


def main(keys=True, path=None):
    sway = Sway(path)
    try:
        lock = claim(sway)
    except ConnectionError as error:
        print(f"swaytiles: {error}", file=sys.stderr)
        return 1
    if lock is None:
        print("swaytiles: another daemon already runs for this sway session", file=sys.stderr)
        return 2
    for number in (signal.SIGTERM, signal.SIGINT, signal.SIGHUP):
        signal.signal(number, stop)
    daemon, alive = Daemon(sway, keys), True
    try:
        alive = daemon.run()
    except ConnectionError:
        alive = False
    finally:
        if alive:
            with contextlib.suppress(OSError, ValueError):
                closing = Sway(sway.path, timeout=2)
                daemon.restore(closing)
                daemon.give_back(closing)
        lock.close()
    return 0


def select(sway, choice):
    if choice in LAYOUTS:
        sway.tick(f"layout {choice}")

def act(sway, action):
    sway.tick(f"{ACT} {action}")
    return 0


def cli():
    arguments = sys.argv[1:]
    try:
        if set(arguments) <= {"--no-keys", "--wait"} and len(set(arguments)) == len(arguments):
            return (wait if "--wait" in arguments else main)(keys="--no-keys" not in arguments)
        if len(arguments) == 1 and arguments[0] in LAYOUTS:
            return select(Sway(), arguments[0])
    except ConnectionError as error:
        print(f"swaytiles: {error}", file=sys.stderr)
        return 1
    usage = "usage: swaytiles [--wait] [--no-keys] | swaytiles LAYOUT\nlayouts: " + ", ".join(LAYOUTS)
    print(usage, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(cli())
