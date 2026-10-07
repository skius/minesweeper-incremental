class_name Content
extends RefCounted

const VERSION = "1.0.0"
const REGION_LENGTH = 16
const CAMPAIGN_LENGTH = 96
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
	{"id":"lens", "name":"Survey lens", "group":0, "cost":40, "cores":0, "rank":0, "pre":"", "icon":"lens", "desc":"Hover a clue to outline its neighbours and count your flags."},
	{"id":"probe2", "name":"Twin pulse", "group":0, "cost":140, "cores":1, "rank":1, "pre":"", "icon":"pulse", "desc":"Your free probe opens two safe tiles instead of one."},
	{"id":"cross", "name":"Crossbeam", "group":0, "cost":260, "cores":2, "rank":3, "pre":"", "icon":"cross", "desc":"New tool: safely sweep a cross through the selected tile. Costs 6 energy."},
	{"id":"battery", "name":"Seed capacitor", "group":0, "cost":420, "cores":2, "rank":6, "pre":"", "icon":"battery", "desc":"Store 18 energy. Every uncovered pocket refills 4 energy."},
	{"id":"line", "name":"Horizon beam", "group":0, "cost":950, "cores":3, "rank":13, "pre":"cross", "icon":"line", "desc":"New tool: reveal every safe tile in the selected row. Costs 10 energy."},
	{"id":"prism", "name":"Prism echo", "group":0, "cost":1700, "cores":3, "rank":22, "pre":"probe2", "icon":"prism", "desc":"Crystal pockets also open a safe neighbour. Probe opens three tiles."},
	{"id":"nova", "name":"Nova charge", "group":0, "cost":3800, "cores":5, "rank":43, "pre":"line", "icon":"nova", "desc":"New tool: sweep a safe 5 by 5 area. Costs 16 energy; capacity becomes 24."},
	{"id":"resonance", "name":"Resonance", "group":0, "cost":6200, "cores":5, "rank":61, "pre":"nova", "icon":"pulse", "desc":"Every tool reveal earns energy back. Smart sweeps skip already open ground."},
	{"id":"drone", "name":"Scout drone", "group":1, "cost":220, "cores":2, "rank":2, "pre":"", "icon":"drone", "desc":"A companion opens one logically safe tile every 3 seconds. Never guesses."},
	{"id":"flagger", "name":"Cartographer", "group":1, "cost":450, "cores":2, "rank":5, "pre":"drone", "icon":"flag", "desc":"Your drone also marks mines proven by adjacent clues."},
	{"id":"pair", "name":"Wingmate", "group":1, "cost":850, "cores":3, "rank":11, "pre":"drone", "icon":"drone", "desc":"A second drone joins. Both act each cycle, with independent deductions."},
	{"id":"logic", "name":"Pattern engine", "group":1, "cost":1600, "cores":3, "rank":19, "pre":"flagger", "icon":"prism", "desc":"Drones compare overlapping clue groups to find subtler safe moves."},
	{"id":"fleet", "name":"Fieldwork fleet", "group":1, "cost":2800, "cores":4, "rank":31, "pre":"pair", "icon":"fleet", "desc":"Four drones work at once. Recovered pockets briefly accelerate the fleet."},
	{"id":"oracle", "name":"Oracle beacon", "group":1, "cost":4400, "cores":5, "rank":47, "pre":"logic", "icon":"lens", "desc":"When logic stalls, the fleet spends 3 energy to probe safe ground."},
	{"id":"swarm", "name":"Daybreak swarm", "group":1, "cost":7000, "cores":6, "rank":65, "pre":"fleet", "icon":"fleet", "desc":"Eight drones. Each cycle paints a sweeping ribbon across the field."},
	{"id":"overdrive", "name":"Solar overdrive", "group":1, "cost":10000, "cores":6, "rank":80, "pre":"swarm", "icon":"nova", "desc":"New tool: 12 seconds of rapid fleet cycles. Costs 12 energy."},
	{"id":"salvage", "name":"Charge reclamation", "group":2, "cost":100, "cores":1, "rank":1, "pre":"", "icon":"flag", "desc":"Correct flags pay 8 light at completion. A reason to mark the whole field."},
	{"id":"chain", "name":"Chain reactor", "group":2, "cost":350, "cores":2, "rank":4, "pre":"", "icon":"cross", "desc":"Safe manual reveals build a persistent multiplier, up to 3 times light."},
	{"id":"shield", "name":"Soft landing", "group":2, "cost":600, "cores":2, "rank":9, "pre":"", "icon":"shield", "desc":"The first mine hit per expedition keeps your chain and energy intact."},
	{"id":"chord", "name":"Cascade circuit", "group":2, "cost":1100, "cores":3, "rank":16, "pre":"chain", "icon":"cross", "desc":"Chording safely triggers other satisfied clues in a continuous cascade."},
	{"id":"bounty", "name":"Pocket refinery", "group":2, "cost":2100, "cores":3, "rank":26, "pre":"salvage", "icon":"prism", "desc":"Pockets produce 25 extra light. Every perfect clear awards an extra core."},
	{"id":"capacitor", "name":"Induction loop", "group":2, "cost":3300, "cores":4, "rank":37, "pre":"battery", "icon":"battery", "desc":"Correct flags store energy. Passive energy returns twice as fast."},
	{"id":"relay", "name":"Relay network", "group":2, "cost":5100, "cores":5, "rank":55, "pre":"chord", "icon":"line", "desc":"Start expeditions with two extra safe openings. Drone reveals pay full light."},
	{"id":"aurora", "name":"Aurora protocol", "group":2, "cost":8400, "cores":6, "rank":73, "pre":"relay", "icon":"nova", "desc":"Clearing a field refills all energy. Pockets trigger free safe crossbeams."}
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

static func contract(index: int, trial: int = -1) -> Dictionary:
	var region := region_for(index)
	var step := index % REGION_LENGTH
	var width := 8 + region + mini(step / 5, 2)
	var height := 7 + region / 2 + mini(step / 7, 2)
	if region >= 4:
		width += 1
		height += 1
	var density := 0.13 + region * 0.013 + (step % 4) * 0.009
	if trial >= 0:
		width = 11 + trial / 3
		height = 9 + trial / 4
		density = 0.19 + (trial % 3) * 0.015
	return {"width":width,"height":height,"mines":int(width * height * density),"seed":71093 + index * 7919 + maxi(trial, 0) * 11003,"region":region,"step":step,"trial":trial,"finale":step == 15}

static func upgrade(id: String) -> Dictionary:
	for item in UPGRADES:
		if item.id == id:
			return item
	return {}

static func title_for(index: int) -> String:
	var nouns = ["First footsteps", "A quiet signal", "Under the surface", "The long way home", "Fragments of light", "A promising frequency", "Small discoveries", "The shape of silence", "Another little sunrise", "A line in the dust", "Where we left off", "Signals from the deep", "Almost a memory", "An open horizon", "The last approach", "Restore the relay"]
	return nouns[index % REGION_LENGTH]
