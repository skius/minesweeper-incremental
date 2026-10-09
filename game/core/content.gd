class_name Content
extends RefCounted

const VERSION = "1.2.1"
const REGION_LENGTH = 16
const CAMPAIGN_LENGTH = 96
# Width, height, density, plating, terrain. Each optional pair offers a compact
# manual survey and a broader fleet field, scaled to its restored region.
const TRIAL_FIELDS = [
	[11,9,0.19,0,"legacy"], [11,9,0.205,0,"legacy"],
	[10,16,0.24,2,"shaft"], [20,9,0.25,2,"shelf"],
	[12,18,0.27,3,"shaft"], [17,17,0.28,3,"geode"],
	[18,18,0.29,4,"geode"], [24,14,0.30,4,"shelf"],
	[14,18,0.32,5,"shaft"], [26,16,0.33,5,"shelf"],
	[18,18,0.35,6,"geode"], [26,18,0.36,6,"shelf"]
]
const REGIONS = [
	{"name":"The Shallows", "tag":"A SMALL BEGINNING", "color":"78dfbd", "rule":"Rich soil", "effect":"Every reveal collects light. Clear safe ground to restore the relay.", "story":"There is still a light on the shore.\nSomeone left it burning for us.", "end":"The first relay answers. Beneath the static, you hear the sea. There are five more signals beyond the horizon."},
	{"name":"Glass Tides", "tag":"THE SEA REMEMBERS", "color":"83c9ed", "rule":"Crystal pockets", "effect":"Buried crystals award triple light. The prism upgrade makes them echo.", "story":"These waves have stood still for a century.\nLet's give them somewhere to go.", "end":"The glass breaks into water. Your little machines discover the delight of getting their feet wet."},
	{"name":"Verdant Coil", "tag":"SOMETHING IS GROWING", "color":"b6d783", "rule":"Living batteries", "effect":"Uncover a seed to refill your tool energy. Growth follows careful hands.", "story":"Roots grew around the sleeping cables.\nThey never stopped waiting for the sun.", "end":"The forest wakes in a slow green wave. A bird tries out a note, then another. Your fleet listens."},
	{"name":"Ember Steps", "tag":"HEAT BENEATH THE DUST", "color":"efad7b", "rule":"Thermal chains", "effect":"Every eighth manual reveal vents heat, opening an extra safe tile.", "story":"The furnaces are cold, but not empty.\nEven an ember remembers what it was.", "end":"The old foundry makes its first new part: a tiny copper wing. It was never meant only to build weapons."},
	{"name":"The Night Archive", "tag":"A THOUSAND QUIET VOICES", "color":"bda9ec", "rule":"Memory echoes", "effect":"Recovered archives identify a hidden mine. Listen for their chime.", "story":"Every light was someone's window.\nEvery window held a story.", "end":"The archive opens. Not orders, not warnings: recipes, music, the names of dogs. A world worth bringing back."},
	{"name":"Dawn Engine", "tag":"ONE LAST HORIZON", "color":"f2cf81", "rule":"Solar current", "effect":"Relays overclock your drones for ten seconds. Bring the whole fleet.", "story":"The sky is a machine we forgot how to start.\nWe have learned enough to try.", "end":"Morning comes without an alarm. The fleet settles on the hillside, warm in the new light. For the first time, there is nothing left to rescue. Only a world to explore."}
]

# Each purchase changes a rule, ability, information source or automation behaviour.
const UPGRADES = [
	{"id":"lens","name":"Survey lens","group":-1,"cost":24,"cores":0,"rank":0,"pre":"","icon":"lens","desc":"A survey lens lights up the eight neighbours of any clue.","branch":-1,"depth":0,"side":0},
	{"id":"salvage","name":"Charge reclamation","group":2,"cost":100,"cores":1,"rank":1,"pre":"lens","icon":"flag","desc":"Correct flags pay 8 light when each stratum clears.","branch":5,"depth":1,"side":-1},
	{"id":"probe2","name":"Twin pulse","group":0,"cost":140,"cores":1,"rank":1,"pre":"lens","icon":"pulse","desc":"Your free probe opens two safe tiles instead of one.","branch":0,"depth":1,"side":-1},
	{"id":"drone","name":"Scout drone","group":1,"cost":100,"cores":1,"rank":0,"pre":"lens","icon":"drone","desc":"A companion opens one logically safe tile every 3 seconds. Never guesses.","branch":1,"depth":1,"side":-1},
	{"id":"chain","name":"Chain reactor","group":2,"cost":350,"cores":2,"rank":2,"pre":"lens","icon":"cross","desc":"Safe manual reveals build a persistent multiplier, up to 3 times light.","branch":3,"depth":1,"side":-1},
	{"id":"focus","name":"Focused pulse","group":0,"cost":160,"cores":1,"rank":3,"pre":"probe2","icon":"lens","desc":"Aim Pulse at a tile. It finds safe ground closest to your cursor.","branch":0,"depth":1,"side":1},
	{"id":"cross","name":"Crossbeam","group":0,"cost":100,"cores":1,"rank":0,"pre":"lens","icon":"cross","desc":"New tool: safely sweep a cross through the selected tile. Costs 6 energy.","branch":0,"depth":2,"side":1},
	{"id":"flagger","name":"Cartographer","group":1,"cost":450,"cores":2,"rank":5,"pre":"drone","icon":"flag","desc":"Your drone also marks mines proven by adjacent clues.","branch":1,"depth":1,"side":1},
	{"id":"battery","name":"Seed capacitor","group":2,"cost":420,"cores":2,"rank":6,"pre":"lens","icon":"battery","desc":"Store 18 energy. Every uncovered pocket refills 4 energy.","branch":2,"depth":1,"side":-1},
	{"id":"drill","name":"Diamond pick","group":2,"cost":220,"cores":1,"rank":6,"pre":"chain","icon":"line","desc":"Manual work breaks three layers of plating in a single hit.","branch":3,"depth":1,"side":1},
	{"id":"shield","name":"Soft landing","group":2,"cost":600,"cores":2,"rank":9,"pre":"salvage","icon":"shield","desc":"The first mine hit per expedition keeps your chain and energy intact.","branch":5,"depth":1,"side":1},
	{"id":"prism","name":"Prism echo","group":2,"cost":700,"cores":3,"rank":10,"pre":"lens","icon":"prism","desc":"Pockets open an extra safe tile through any plating. Pulse opens three tiles.","branch":4,"depth":1,"side":-1},
	{"id":"pair","name":"Wingmate","group":1,"cost":850,"cores":3,"rank":11,"pre":"drone","icon":"drone","desc":"A second drone joins. Both act each cycle, with independent deductions.","branch":1,"depth":2,"side":-1},
	{"id":"reservoir","name":"Pulse reservoir","group":0,"cost":650,"cores":2,"rank":12,"pre":"focus","icon":"battery","desc":"Store two free pulses. Save one for the next uncertain corner.","branch":0,"depth":2,"side":-1},
	{"id":"flywheel","name":"Flywheel","group":2,"cost":850,"cores":2,"rank":15,"pre":"battery","icon":"pulse","desc":"A successful chord fully recharges one free Pulse.","branch":2,"depth":1,"side":1},
	{"id":"chord","name":"Cascade circuit","group":2,"cost":1100,"cores":3,"rank":16,"pre":"chain","icon":"cross","desc":"Chording safely triggers other satisfied clues in a continuous cascade.","branch":3,"depth":2,"side":1},
	{"id":"harvester","name":"Charge painter","group":2,"cost":950,"cores":2,"rank":17,"pre":"salvage","icon":"flag","desc":"Beams mark every charge in their footprint, ready for chording.","branch":5,"depth":2,"side":-1},
	{"id":"diagonal","name":"Eightfold beam","group":0,"cost":1100,"cores":2,"rank":18,"pre":"cross","icon":"cross","desc":"Crossbeam grows four diagonal arms.","branch":0,"depth":3,"side":-1},
	{"id":"logic","name":"Pattern engine","group":1,"cost":1600,"cores":3,"rank":19,"pre":"flagger","icon":"prism","desc":"Drones compare overlapping clue groups to find subtler safe moves.","branch":1,"depth":3,"side":-1},
	{"id":"fracture","name":"Fault lines","group":2,"cost":1300,"cores":2,"rank":21,"pre":"drill","icon":"cross","desc":"Breaking a plate cracks the neighbouring plates too.","branch":3,"depth":2,"side":-1},
	{"id":"line","name":"Horizon beam","group":0,"cost":950,"cores":3,"rank":24,"pre":"cross","icon":"line","desc":"New tool: reveal every safe tile in the selected row. Costs 10 energy.","branch":0,"depth":4,"side":-1},
	{"id":"compass","name":"Crystal compass","group":2,"cost":1500,"cores":2,"rank":25,"pre":"prism","icon":"prism","desc":"See buried crystal pockets before uncovering them.","branch":4,"depth":1,"side":1},
	{"id":"bounty","name":"Pocket refinery","group":2,"cost":2100,"cores":3,"rank":26,"pre":"salvage","icon":"prism","desc":"Pockets yield 25 extra light. Perfect sites also award an extra core.","branch":5,"depth":2,"side":1},
	{"id":"kinetic","name":"Kinetic collector","group":2,"cost":3500,"cores":3,"rank":53,"pre":"flywheel","icon":"battery","desc":"Breaking plates by hand produces energy and recharges Pulse.","branch":2,"depth":2,"side":-1},
	{"id":"excavator","name":"Excavator chassis","group":1,"cost":1900,"cores":3,"rank":28,"pre":"pair","icon":"drone","desc":"Drones break three layers of plating per visit.","branch":1,"depth":2,"side":1},
	{"id":"perforator","name":"Bore laser","group":0,"cost":2400,"cores":3,"rank":30,"pre":"diagonal","icon":"line","desc":"Every beam hit breaks four layers of buried plating.","branch":0,"depth":3,"side":1},
	{"id":"fleet","name":"Fieldwork fleet","group":1,"cost":2800,"cores":4,"rank":31,"pre":"excavator","icon":"fleet","desc":"Four drones work at once. Recovered pockets briefly accelerate the fleet.","branch":1,"depth":4,"side":-1},
	{"id":"echochamber","name":"Hollow resonance","group":2,"cost":6400,"cores":3,"rank":69,"pre":"harvester","icon":"pulse","desc":"Opening a zero-clue cavern restores one free Pulse.","branch":5,"depth":3,"side":-1},
	{"id":"relay","name":"Relay network","group":2,"cost":5100,"cores":5,"rank":36,"pre":"compass","icon":"line","desc":"Start expeditions with two extra safe openings. Drone reveals pay full light.","branch":4,"depth":2,"side":1},
	{"id":"capacitor","name":"Induction loop","group":2,"cost":3300,"cores":4,"rank":37,"pre":"battery","icon":"battery","desc":"Drone-mapped charges restore energy. Passive energy returns twice as fast.","branch":2,"depth":2,"side":1},
	{"id":"sentry","name":"Rescue flare","group":2,"cost":6000,"cores":3,"rank":67,"pre":"shield","icon":"shield","desc":"A protected strike sends a free safe probe into the field.","branch":5,"depth":4,"side":-1},
	{"id":"cartogram","name":"Deep scanner","group":2,"cost":9300,"cores":3,"rank":87,"pre":"compass","icon":"lens","desc":"Unfocused pulses seek the largest new opening, instead of the nearest edge.","branch":4,"depth":2,"side":-1},
	{"id":"vertical","name":"Meridian","group":0,"cost":3700,"cores":4,"rank":42,"pre":"line","icon":"cross","desc":"Horizon cuts a full column as well as a row.","branch":0,"depth":4,"side":1},
	{"id":"nova","name":"Nova charge","group":0,"cost":3800,"cores":5,"rank":43,"pre":"line","icon":"nova","desc":"New tool: sweep a safe 5 by 5 area. Costs 16 energy; capacity becomes 24.","branch":0,"depth":5,"side":-1},
	{"id":"synchrony","name":"Coordinated strike","group":1,"cost":4200,"cores":4,"rank":45,"pre":"logic","icon":"fleet","desc":"A successful manual chord calls an immediate fleet cycle.","branch":1,"depth":3,"side":1},
	{"id":"seismic","name":"Seismic rhythm","group":2,"cost":4500,"cores":4,"rank":46,"pre":"fracture","icon":"nova","desc":"Every sixth manual excavation sends a safe crossbeam through that tile.","branch":3,"depth":3,"side":-1},
	{"id":"oracle","name":"Oracle beacon","group":1,"cost":4400,"cores":5,"rank":47,"pre":"logic","icon":"lens","desc":"When logic stalls, the fleet spends 3 energy to probe safe ground.","branch":1,"depth":4,"side":1},
	{"id":"magnet","name":"Pocket gravity","group":2,"cost":8800,"cores":4,"rank":83,"pre":"bounty","icon":"prism","desc":"Each pocket pulls open two more safe tiles nearby.","branch":5,"depth":3,"side":1},
	{"id":"launchpad","name":"Launch rail","group":2,"cost":4300,"cores":4,"rank":51,"pre":"relay","icon":"drone","desc":"The fleet makes the first safe opening on each new stratum.","branch":4,"depth":3,"side":-1},
	{"id":"supercap","name":"Storm capacitor","group":2,"cost":5700,"cores":4,"rank":57,"pre":"capacitor","icon":"battery","desc":"Store 40 energy: enough to combine Nova and Horizon.","branch":2,"depth":3,"side":-1},
	{"id":"conductor","name":"Clue conductor","group":2,"cost":8400,"cores":4,"rank":81,"pre":"chord","icon":"prism","desc":"Click a clue to open neighbours proved safe, even without placing flags.","branch":3,"depth":3,"side":1},
	{"id":"resonance","name":"Resonance","group":2,"cost":6200,"cores":5,"rank":61,"pre":"supercap","icon":"pulse","desc":"Every tool reveal earns energy back. Smart sweeps skip already open ground.","branch":2,"depth":3,"side":1},
	{"id":"crucible","name":"Shard furnace","group":2,"cost":6000,"cores":4,"rank":70,"pre":"echochamber","icon":"battery","desc":"Every shattered plate, including drone work, fuels your tools.","branch":5,"depth":4,"side":-1},
	{"id":"swarm","name":"Daybreak swarm","group":1,"cost":7000,"cores":6,"rank":65,"pre":"fleet","icon":"fleet","desc":"Eight drones. Each cycle paints a sweeping ribbon across the field.","branch":1,"depth":5,"side":-1},
	{"id":"autodescent","name":"Autonomous descent","group":2,"cost":7500,"cores":5,"rank":71,"pre":"launchpad","icon":"fleet","desc":"The fleet descends to the next stratum by itself. New sites still await your signal.","branch":4,"depth":3,"side":1},
	{"id":"aurora","name":"Aurora protocol","group":2,"cost":8400,"cores":6,"rank":73,"pre":"autodescent","icon":"nova","desc":"Clearing each stratum refills all energy. Pockets trigger safe crossbeams.","branch":4,"depth":4,"side":-1},
	{"id":"aftershock","name":"Event horizon","group":0,"cost":8500,"cores":6,"rank":76,"pre":"nova","icon":"nova","desc":"Nova grows to 7 by 7 and cracks every plate inside.","branch":0,"depth":5,"side":1},
	{"id":"recycler","name":"Closed circuit","group":2,"cost":8000,"cores":5,"rank":78,"pre":"resonance","icon":"battery","desc":"Beams refund energy for open tiles in their footprint. Precision becomes optional.","branch":2,"depth":4,"side":-1},
	{"id":"overdrive","name":"Solar overdrive","group":1,"cost":10000,"cores":6,"rank":80,"pre":"swarm","icon":"nova","desc":"12 seconds of 10× fleet speed. Costs 12 energy; stores 24 energy.","branch":1,"depth":5,"side":1},
	{"id":"legacy","name":"Unbroken current","group":2,"cost":11000,"cores":6,"rank":91,"pre":"aurora","icon":"nova","desc":"Your chain carries between strata and sites. All excavation breaks six plate layers.","branch":4,"depth":4,"side":1}
]

const TRANSMISSIONS = [
	"FIELD NOTE 01|A clue counts charges in all eight neighbouring tiles. A corner can still be dangerous.",
	"FIELD NOTE 02|Flags are your notes. A wrong flag can make a chord unsafe; remove it with another right click.",
	"FIELD NOTE 03|A charged probe never guesses. Use it whenever the visible clues leave two possibilities.",
	"FIELD NOTE 04|Drones read the same clues you do. Give them a new opening when their status says waiting.",
	"FIELD NOTE 05|The chain has no timer. Take your time. This world has waited long enough.",
	"FIELD NOTE 06|A perfect clear means no mine strikes. Tools and drones are welcome; good equipment is part of fieldwork.",
	"FIELD NOTE 07|Energy refills during an expedition. Safe manual work is the fastest way to replenish it.",
	"FIELD NOTE 08|Correct flags earn their bonus when you clear the field. Moving a flag cannot farm light."
]

static func region_for(index: int) -> int:
	return mini(index / REGION_LENGTH, 5)

static func contract(index: int, trial: int = -1, stratum: int = 0) -> Dictionary:
	var region := trial/2 if trial>=0 else region_for(index)
	var step := index % REGION_LENGTH
	var width: int = [9,13,16,19,22,24][region] + step / 8
	var height: int = [8,10,12,13,14,16][region] + (1 if step >= 8 and region < 4 else 0)
	var density := 0.16 + region * 0.024 + (step % 4) * 0.008 + minf(stratum * 0.002,0.015)
	var form := "legacy"
	var crust := 0 if index<6 else mini(6,maxi(2,1+region+stratum/4))
	if index < 3:
		width = 6 + index
		height = 5 + index
		density = 0.13 + index * 0.015
	if trial >= 0:
		var field: Array=TRIAL_FIELDS[trial]
		width=field[0]
		height=field[1]
		density=field[2]
		crust=field[3]
		form=field[4]
	elif index >= 6:
		# Shape and terrain change how a toolkit is used, rather than adding
		# another copy of the same rectangle. Adjacent strata always differ.
		form = ["shelf", "shaft", "geode"][(index - 6 + stratum) % 3]
		match form:
			"shelf":
				width = mini(26, [13,17,20,22,24,26][region] + step / 8)
				height = [6,8,10,12,13,15][region]
			"shaft":
				width = mini(14, [7,9,10,11,12,13][region] + step / 8)
				height = mini(18, [11,13,15,16,17,18][region] + step / 8)
			"geode":
				width = mini(18, [9,12,14,16,17,18][region] + step / 8)
				height = width
	var board_seed := 350003+trial*11003 if trial>=0 else 71093+index*7919+stratum*104729
	return {"width":width,"height":height,"mines":int(width * height * density),"seed":board_seed,"region":region,"step":step,"trial":trial,"finale":step == 15 and trial<0,"crust":crust,"form":form}

static func upgrade(id: String) -> Dictionary:
	for item in UPGRADES:
		if item.id == id:
			return item
	return {}

static func title_for(index: int) -> String:
	var nouns = ["First footsteps", "A quiet signal", "Under the surface", "The long way home", "Fragments of light", "A promising frequency", "Small discoveries", "The shape of silence", "Another little sunrise", "A line in the dust", "Where we left off", "Signals from the deep", "Almost a memory", "An open horizon", "The last approach", "Restore the relay"]
	return nouns[index % REGION_LENGTH]

const BRANCH_NAMES = ["BEAMS", "FLEET", "ENERGY", "CRAFT", "DISCOVERY", "ALCHEMY"]
const BRANCH_COLORS = ["7bdde8","efbf77","e9dd97","ed9b87","b6a4e5","8bd6a6"]

static func strata_for(index: int, trial: int = -1) -> int:
	if trial >= 0 or index < 4:
		return 1
	return [2,3,5,7,9,12][region_for(index)] + (1 if index % REGION_LENGTH >= 12 else 0)

# Positions follow dependency forks, so branches never double back across their parent.
const TREE_LAYOUT = {
	"probe2":[0,145,0],"focus":[0,240,-60],"reservoir":[0,345,-100],"cross":[0,240,60],"diagonal":[0,345,115],"perforator":[0,460,145],"line":[0,345,10],"vertical":[0,460,35],"nova":[0,460,-55],"aftershock":[0,560,-70],
	"drone":[1,145,0],"flagger":[1,245,-60],"logic":[1,345,-90],"oracle":[1,455,-125],"synchrony":[1,455,-25],"pair":[1,245,60],"excavator":[1,345,100],"fleet":[1,455,120],"swarm":[1,555,140],"overdrive":[1,650,160],
	"battery":[2,145,0],"flywheel":[2,245,-60],"kinetic":[2,345,-90],"capacitor":[2,245,60],"supercap":[2,345,95],"resonance":[2,445,125],"recycler":[2,555,150],
	"chain":[3,145,0],"drill":[3,245,-60],"fracture":[3,345,-90],"seismic":[3,455,-125],"chord":[3,245,60],"conductor":[3,355,100],
	"prism":[4,145,0],"compass":[4,245,0],"cartogram":[4,355,-75],"relay":[4,355,70],"launchpad":[4,455,75],"autodescent":[4,555,85],"aurora":[4,650,100],"legacy":[4,745,115],
	"salvage":[5,145,0],"shield":[5,245,-80],"sentry":[5,365,-125],"harvester":[5,245,80],"echochamber":[5,365,125],"crucible":[5,475,145],"bounty":[5,260,0],"magnet":[5,380,0]
}

static func tree_position(item: Dictionary) -> Vector2:
	if item.id == "lens":
		return Vector2.ZERO
	var placement: Array = TREE_LAYOUT[item.id]
	var direction := Vector2.from_angle(placement[0]*TAU/6-PI/2)
	return direction*placement[1]+direction.orthogonal()*placement[2]
