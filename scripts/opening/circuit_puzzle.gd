class_name CircuitPuzzle
extends RefCounted
## Last Signal — opening sequence: pure circuit-puzzle logic (no UI).
##
## 5x4 grid of wire components. The player rotates tiles until electricity
## can travel from the emergency power source to the medical section's
## power output. Solved is determined ONLY by real connectivity (BFS over
## matching ports), never by a rotation counter or a hardcoded trigger:
## there must be a continuous path source -> fuse -> output, so the fuse
## is always part of the live circuit.
##
## Ports are numbered clockwise: 0 = North, 1 = East, 2 = South, 3 = West.
## Rotating a tile turns its ports 90 degrees clockwise. Source and output
## are fixed and cannot rotate. Straight and fuse tiles have two distinct
## orientations; rotating them twice returns to the start, so no rotation
## can ever make the puzzle unsolvable.

enum Kind { STRAIGHT, CORNER, THREE_WAY, FUSE, SOURCE, OUTPUT }

const COLS := 5
const ROWS := 4

## Clockwise port numbers: N, E, S, W.
const DIRS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0),
]

const SOURCE_CELL := Vector2i(0, 1)
const OUTPUT_CELL := Vector2i(4, 2)
const FUSE_CELL := Vector2i(2, 1)

## Ports of each kind at rotation 0.
const BASE_PORTS := {
	Kind.STRAIGHT: [0, 2],
	Kind.CORNER: [0, 1],
	Kind.THREE_WAY: [0, 1, 2],
	Kind.FUSE: [0, 2],
	Kind.SOURCE: [1],
	Kind.OUTPUT: [3],
}

## Predefined layout. Each entry: [kind, initial rotation]. The intended
## solution path is source (0,1) -> (1,1) -> fuse (2,1) -> (3,1) ->
## (3,2) -> output (4,2); solving it needs 5 rotations (1,1) x1, fuse x1,
## (3,1) x1, (3,2) x2. All other tiles are filler: they look like a busy
## panel but cannot bypass the fuse, because the source only exits east
## into (1,1), which only exits east into the fuse.
const DEFAULT_LAYOUT: Array = [
	# Row 0
	[Kind.CORNER, 0], [Kind.STRAIGHT, 1], [Kind.CORNER, 0], [Kind.STRAIGHT, 0], [Kind.CORNER, 1],
	# Row 1
	[Kind.SOURCE, 0], [Kind.STRAIGHT, 0], [Kind.FUSE, 0], [Kind.CORNER, 1], [Kind.STRAIGHT, 0],
	# Row 2
	[Kind.STRAIGHT, 1], [Kind.CORNER, 2], [Kind.STRAIGHT, 1], [Kind.CORNER, 2], [Kind.OUTPUT, 0],
	# Row 3
	[Kind.CORNER, 0], [Kind.STRAIGHT, 1], [Kind.CORNER, 3], [Kind.THREE_WAY, 0], [Kind.CORNER, 1],
]

## Solved rotations for the four tiles on the solution path (the rest of
## the grid may sit in any orientation; they cannot complete the circuit).
const SOLUTION_ROTATIONS := {
	Vector2i(1, 1): 1,
	Vector2i(2, 1): 1,
	Vector2i(3, 1): 2,
	Vector2i(3, 2): 0,
}

var _cells: Array = []


static func default_puzzle() -> CircuitPuzzle:
	var puzzle := CircuitPuzzle.new()
	for entry in DEFAULT_LAYOUT:
		puzzle._cells.append({"kind": entry[0], "rot": entry[1]})
	return puzzle


func _index(cell: Vector2i) -> int:
	return cell.y * COLS + cell.x


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS


func kind_at(cell: Vector2i) -> int:
	return _cells[_index(cell)]["kind"]


func rotation_at(cell: Vector2i) -> int:
	return _cells[_index(cell)]["rot"]


func is_rotatable(cell: Vector2i) -> bool:
	var kind: int = kind_at(cell)
	return kind != Kind.SOURCE and kind != Kind.OUTPUT


## Ports of the tile at `cell` after its current rotation, sorted so the
## same connection set always compares equal.
func ports_at(cell: Vector2i) -> Array[int]:
	var kind: int = kind_at(cell)
	var rot: int = rotation_at(cell)
	var ports: Array[int] = []
	for p in BASE_PORTS[kind]:
		ports.append((int(p) + rot) % 4)
	ports.sort()
	return ports


## Rotate the tile 90 degrees clockwise. Source and output ignore it.
func rotate(cell: Vector2i) -> void:
	if not in_bounds(cell) or not is_rotatable(cell):
		return
	_cells[_index(cell)]["rot"] = (rotation_at(cell) + 1) % 4


## True when the tile can carry current from `from_cell` towards it, i.e.
## both tiles expose the shared side.
func _links(a: Vector2i, b: Vector2i) -> bool:
	if not in_bounds(a) or not in_bounds(b):
		return false
	for d in range(4):
		if b == a + DIRS[d]:
			return ports_at(a).has(d) and ports_at(b).has((d + 2) % 4)
	return false


## All cells reachable from `start` through matching ports.
func _reachable(start: Vector2i) -> Dictionary:
	var seen := {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for d in range(4):
			var next: Vector2i = cell + DIRS[d]
			if not in_bounds(next) or seen.has(next):
				continue
			if _links(cell, next):
				seen[next] = true
				queue.append(next)
	return seen


## Breadth-first path from `start` to `goal` (empty when unreachable).
func _bfs_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	if start == goal:
		return [start]
	var parent := {start: start}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for d in range(4):
			var next: Vector2i = cell + DIRS[d]
			if not in_bounds(next) or parent.has(next):
				continue
			if _links(cell, next):
				parent[next] = cell
				if next == goal:
					var path: Array[Vector2i] = [goal]
					var cur: Vector2i = goal
					while cur != start:
						cur = parent[cur]
						path.push_front(cur)
					return path
				queue.append(next)
	return []


## The live path source -> fuse -> output, or empty when either leg is
## broken. This is the ONLY definition of solved: a real, continuous,
## fuse-protected connection.
func solve_path() -> Array[Vector2i]:
	var first := _bfs_path(SOURCE_CELL, FUSE_CELL)
	if first.is_empty():
		return []
	var second := _bfs_path(FUSE_CELL, OUTPUT_CELL)
	if second.is_empty():
		return []
	second.remove_at(0)  # fuse counted once
	var path: Array[Vector2i] = []
	path.append_array(first)
	path.append_array(second)
	return path


func is_solved() -> bool:
	return not solve_path().is_empty()


## Cells currently carrying power from the source (even before solved),
## for the subtle "live wire" glow in the UI.
func energized_cells() -> Array[Vector2i]:
	var reached := _reachable(SOURCE_CELL)
	var cells: Array[Vector2i] = []
	for cell in reached.keys():
		cells.append(cell)
	return cells


## Adjacent cell pairs whose shared side is connected on both ends, for
## the connection glow between neighbours.
func connected_edges() -> Array:
	var edges: Array = []
	for y in ROWS:
		for x in COLS:
			var cell := Vector2i(x, y)
			var east := cell + Vector2i(1, 0)
			var south := cell + Vector2i(0, 1)
			if in_bounds(east) and _links(cell, east):
				edges.append([cell, east])
			if in_bounds(south) and _links(cell, south):
				edges.append([cell, south])
	return edges
