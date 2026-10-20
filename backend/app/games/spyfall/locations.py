from typing import List, Dict, Any, Optional

LOCATION_CATEGORIES = [
    "Public Places",
    "Transport & Travel",
    "Professional Environments",
    "Leisure & Entertainment",
    "Everyday & Unusual",
]

SPYFALL_LOCATIONS: List[Dict[str, Any]] = [
    # 1. PUBLIC PLACES (15)
    {
        "id": "airport",
        "name": "Airport",
        "category": "Public Places",
        "description": "Busy international hub with boarding gates, luggage carousels, and duty-free shops.",
        "themes": ["passports", "security checkpoint", "boarding gate", "suitcases", "departures"]
    },
    {
        "id": "train_station",
        "name": "Train Station",
        "category": "Public Places",
        "description": "Grand terminal filled with commuters, platform boards, and steam engines.",
        "themes": ["tickets", "conductor", "platform 9", "whistles", "timetables"]
    },
    {
        "id": "bus_station",
        "name": "Bus Station",
        "category": "Public Places",
        "description": "Transit depot with cross-country coaches, vending machines, and waiting benches.",
        "themes": ["tokens", "benches", "transfers", "exhaust", "commuters"]
    },
    {
        "id": "shopping_mall",
        "name": "Shopping Mall",
        "category": "Public Places",
        "description": "Multi-level consumer paradise with escalators, retail stores, and a food court.",
        "themes": ["sale signs", "escalators", "store clerk", "shopping bags", "fountain"]
    },
    {
        "id": "supermarket",
        "name": "Supermarket",
        "category": "Public Places",
        "description": "Grocery store with barcode scanners, aisles of fresh produce, and shopping carts.",
        "themes": ["shopping carts", "checkout lane", "fresh produce", "coupons", "cashier"]
    },
    {
        "id": "restaurant",
        "name": "Restaurant",
        "category": "Public Places",
        "description": "Dining establishment with candlelit tables, menus, chefs, and wine glasses.",
        "themes": ["menus", "waiter", "chef", "reservations", "bills"]
    },
    {
        "id": "hotel",
        "name": "Hotel",
        "category": "Public Places",
        "description": "Upscale accommodation with concierge desk, room keys, and bellhops.",
        "themes": ["reception", "room keys", "concierge", "room service", "bellhop"]
    },
    {
        "id": "hospital",
        "name": "Hospital",
        "category": "Public Places",
        "description": "Medical facility staffed by doctors, nurses, stethoscopes, and emergency gurneys.",
        "themes": ["surgeons", "stethoscopes", "scrubs", "prescriptions", "emergency room"]
    },
    {
        "id": "university",
        "name": "University",
        "category": "Public Places",
        "description": "Higher education campus featuring lecture halls, professors, and student dorms.",
        "themes": ["professors", "lecture hall", "textbooks", "graduations", "campus quad"]
    },
    {
        "id": "library",
        "name": "Library",
        "category": "Public Places",
        "description": "Quiet sanctuary lined with towering bookshelves, reading lamps, and study carrels.",
        "themes": ["silence", "bookshelves", "librarian", "borrow cards", "archives"]
    },
    {
        "id": "museum",
        "name": "Museum",
        "category": "Public Places",
        "description": "Cultural institution with ancient artifacts, dinosaur fossils, and velvet ropes.",
        "themes": ["curator", "exhibits", "artifacts", "audio guides", "sculptures"]
    },
    {
        "id": "cinema",
        "name": "Cinema",
        "category": "Public Places",
        "description": "Movie theater with rows of plush red seats, projector beams, and popcorn smells.",
        "themes": ["popcorn", "movie screen", "trailers", "3D glasses", "box office"]
    },
    {
        "id": "amusement_park",
        "name": "Amusement Park",
        "category": "Public Places",
        "description": "Thrilling carnival destination with roller coasters, cotton candy, and ferris wheels.",
        "themes": ["roller coaster", "cotton candy", "ferris wheel", "carnival games", "ticket booth"]
    },
    {
        "id": "zoo",
        "name": "Zoo",
        "category": "Public Places",
        "description": "Wild animal sanctuary with safari enclosures, lion dens, and educational guides.",
        "themes": ["habitats", "zookeepers", "feeding time", "cages", "maps"]
    },
    {
        "id": "aquarium",
        "name": "Aquarium",
        "category": "Public Places",
        "description": "Marine park with underwater glass tunnels, jellyfish tanks, and shark feeding.",
        "themes": ["glass tunnel", "sharks", "tanks", "coral reefs", "touch pools"]
    },

    # 2. TRANSPORT & TRAVEL (10)
    {
        "id": "airplane",
        "name": "Airplane",
        "category": "Transport & Travel",
        "description": "Cruising airliner at 30,000 feet with flight attendants, cockpit, and wing views.",
        "themes": ["cockpit", "flight attendant", "seatbelts", "turbulence", "oxygen masks"]
    },
    {
        "id": "cruise_ship",
        "name": "Cruise Ship",
        "category": "Transport & Travel",
        "description": "Luxury ocean liner with sun decks, captain's bridge, and buffet dining.",
        "themes": ["sun deck", "captain's bridge", "lifeboats", "staterooms", "buffet"]
    },
    {
        "id": "subway",
        "name": "Subway",
        "category": "Transport & Travel",
        "description": "Underground rapid rail car with handrails, tiled stations, and rushing commuters.",
        "themes": ["turnstiles", "metro card", "handrails", "tunnels", "next stop"]
    },
    {
        "id": "taxi",
        "name": "Taxi",
        "category": "Transport & Travel",
        "description": "Urban cab navigating city traffic with a clicking meter and driver radio.",
        "themes": ["taximeter", "fare", "rearview mirror", "honking", "destination"]
    },
    {
        "id": "space_station",
        "name": "Space Station",
        "category": "Transport & Travel",
        "description": "Zero-gravity orbital laboratory with airlocks, solar panels, and Earth observation.",
        "themes": ["zero gravity", "airlock", "solar panels", "spacesuits", "orbit"]
    },
    {
        "id": "railway_platform",
        "name": "Railway Platform",
        "category": "Transport & Travel",
        "description": "Outdoor boarding strip with waiting benches, yellow safety lines, and track signals.",
        "themes": ["safety line", "overhead clock", "track switches", "signals", "luggage carts"]
    },
    {
        "id": "ferry",
        "name": "Ferry",
        "category": "Transport & Travel",
        "description": "Vessel transporting cars and passengers across calm coastal bays.",
        "themes": ["car deck", "sea spray", "gulls", "harbor horn", "life jackets"]
    },
    {
        "id": "highway_rest_stop",
        "name": "Highway Rest Stop",
        "category": "Transport & Travel",
        "description": "Roadside travel plaza with fuel pumps, fast food counters, and vending spots.",
        "themes": ["gas pumps", "vending machines", "semi-trucks", "interstate maps", "coffee"]
    },
    {
        "id": "mountain_cable_car",
        "name": "Mountain Cable Car",
        "category": "Transport & Travel",
        "description": "Glass gondola suspended high above snowy peaks and rocky valleys.",
        "themes": ["gondola", "cables", "panoramic view", "ski poles", "altitude"]
    },
    {
        "id": "camping_ground",
        "name": "Camping Ground",
        "category": "Transport & Travel",
        "description": "Wooded clearing with pitched tents, crackling campfires, and starry night skies.",
        "themes": ["tents", "campfire", "sleeping bags", "marshmallows", "lanterns"]
    },

    # 3. PROFESSIONAL ENVIRONMENTS (13)
    {
        "id": "police_station",
        "name": "Police Station",
        "category": "Professional Environments",
        "description": "Law enforcement precinct with holding cells, detective desks, and sirens.",
        "themes": ["badges", "handcuffs", "holding cell", "mugshots", "sirens"]
    },
    {
        "id": "fire_station",
        "name": "Fire Station",
        "category": "Professional Environments",
        "description": "Emergency depot with brass poles, fire engines, heavy hoses, and boots.",
        "themes": ["brass pole", "fire truck", "hoses", "helmets", "alarm bell"]
    },
    {
        "id": "courtroom",
        "name": "Courtroom",
        "category": "Professional Environments",
        "description": "Judicial chamber with judge's gavel, witness stand, and jury box.",
        "themes": ["gavel", "judge", "witness stand", "jury", "verdict"]
    },
    {
        "id": "bank",
        "name": "Bank",
        "category": "Professional Environments",
        "description": "Financial vault and branch with teller windows, safe deposit boxes, and security guards.",
        "themes": ["vault", "teller", "safe deposit", "cash drawers", "security guards"]
    },
    {
        "id": "office",
        "name": "Office",
        "category": "Professional Environments",
        "description": "Corporate workspace with cubicles, water coolers, meeting rooms, and spreadsheets.",
        "themes": ["cubicles", "water cooler", "slide decks", "swivel chairs", "coffee machine"]
    },
    {
        "id": "construction_site",
        "name": "Construction Site",
        "category": "Professional Environments",
        "description": "Active building zone with yellow hard hats, cranes, scaffolding, and cement mixers.",
        "themes": ["hard hats", "cranes", "blueprints", "scaffolding", "cement mixer"]
    },
    {
        "id": "factory",
        "name": "Factory",
        "category": "Professional Environments",
        "description": "Industrial plant with conveyor belts, assembly robots, and safety goggles.",
        "themes": ["conveyor belt", "assembly line", "safety goggles", "shift whistle", "forklift"]
    },
    {
        "id": "newsroom",
        "name": "Newsroom",
        "category": "Professional Environments",
        "description": "Bustling press hub with ringing phones, deadline clocks, and breaking news tickers.",
        "themes": ["deadline", "press passes", "teleprompter", "headline", "editor"]
    },
    {
        "id": "television_studio",
        "name": "Television Studio",
        "category": "Professional Environments",
        "description": "Broadcasting stage with boom microphones, studio cameras, and green screens.",
        "themes": ["cameras", "on-air sign", "green screen", "director's chair", "teleprompter"]
    },
    {
        "id": "research_laboratory",
        "name": "Research Laboratory",
        "category": "Professional Environments",
        "description": "Scientific facility with petri dishes, electron microscopes, and sterile fume hoods.",
        "themes": ["microscope", "petri dishes", "lab coats", "pipettes", "centrifuge"]
    },
    {
        "id": "embassy",
        "name": "Embassy",
        "category": "Professional Environments",
        "description": "Diplomatic mission with foreign flags, visa officers, and ambassadorial offices.",
        "themes": ["ambassador", "diplomatic pouch", "visas", "foreign flags", "bodyguards"]
    },
    {
        "id": "military_base",
        "name": "Military Base",
        "category": "Professional Environments",
        "description": "Fortified defense compound with barracks, drill sergeants, and guard towers.",
        "themes": ["barracks", "drill sergeant", "dog tags", "guard tower", "camo uniforms"]
    },
    {
        "id": "secret_agent_hq",
        "name": "Secret Agent Headquarters",
        "category": "Professional Environments",
        "description": "Underground spy bunker with surveillance monitors, gadget labs, and biometric doors.",
        "themes": ["gadgets", "fingerprint scanner", "briefings", "classified files", "monitors"]
    },

    # 4. LEISURE & ENTERTAINMENT (11)
    {
        "id": "beach",
        "name": "Beach",
        "category": "Leisure & Entertainment",
        "description": "Sun-drenched coastline with sandcastles, surfboards, seashells, and ocean waves.",
        "themes": ["surfboards", "sunscreen", "sandcastles", "lifeguard tower", "waves"]
    },
    {
        "id": "ski_resort",
        "name": "Ski Resort",
        "category": "Leisure & Entertainment",
        "description": "Alpine lodge surrounded by powdery ski slopes, chairlifts, and hot cocoa mugs.",
        "themes": ["ski lift", "snow goggles", "lodge", "hot chocolate", "slopes"]
    },
    {
        "id": "football_stadium",
        "name": "Football Stadium",
        "category": "Leisure & Entertainment",
        "description": "Colossal sports colosseum with floodlights, goalposts, and roaring crowds.",
        "themes": ["floodlights", "goalposts", "referee whistle", "roaring fans", "scoreboard"]
    },
    {
        "id": "cricket_stadium",
        "name": "Cricket Stadium",
        "category": "Leisure & Entertainment",
        "description": "Lush green oval pitch with wickets, boundary ropes, umpire signals, and pavilion seats.",
        "themes": ["wickets", "boundary rope", "umpire", "pavilion", "cricket bat"]
    },
    {
        "id": "gym",
        "name": "Gym",
        "category": "Leisure & Entertainment",
        "description": "Fitness center with barbells, treadmills, sweat towels, and protein shakes.",
        "themes": ["dumbbells", "treadmills", "mirrors", "protein shake", "lockers"]
    },
    {
        "id": "swimming_pool",
        "name": "Swimming Pool",
        "category": "Leisure & Entertainment",
        "description": "Aquatic center with diving boards, lap lanes, chlorine water, and whistle blows.",
        "themes": ["diving board", "chlorine", "swim lanes", "lifeguards", "kickboards"]
    },
    {
        "id": "concert_venue",
        "name": "Concert Venue",
        "category": "Leisure & Entertainment",
        "description": "Electric arena featuring towering amplifier stacks, stage lasers, and roaring fans.",
        "themes": ["amplifiers", "stage lights", "guitar picks", "mosh pit", "tickets"]
    },
    {
        "id": "casino",
        "name": "Casino",
        "category": "Leisure & Entertainment",
        "description": "Glittering gambling floor with roulette wheels, blackjack tables, and chip stacks.",
        "themes": ["roulette", "poker chips", "croupier", "slot machines", "jackpot"]
    },
    {
        "id": "nightclub",
        "name": "Nightclub",
        "category": "Leisure & Entertainment",
        "description": "Dimly lit dance venue with pulsing strobe lights, DJ turntables, and bass speakers.",
        "themes": ["DJ booth", "strobe lights", "dance floor", "bass drop", "bouncers"]
    },
    {
        "id": "theme_park",
        "name": "Theme Park",
        "category": "Leisure & Entertainment",
        "description": "Storybook kingdom with themed lands, parade floats, and mascot characters.",
        "themes": ["mascots", "parade float", "castle", "souvenir shop", "fast pass"]
    },
    {
        "id": "bowling_alley",
        "name": "Bowling Alley",
        "category": "Leisure & Entertainment",
        "description": "Retro recreational hall with polished wooden lanes, pinsetters, and rental shoes.",
        "themes": ["bowling balls", "pins", "strike", "rental shoes", "gutters"]
    },

    # 5. EVERYDAY & UNUSUAL (15)
    {
        "id": "school",
        "name": "School",
        "category": "Everyday & Unusual",
        "description": "Elementary academy with blackboards, recess bells, desks, and pencil sharpeners.",
        "themes": ["blackboard", "recess bell", "lockers", "backpacks", "chalk"]
    },
    {
        "id": "wedding_venue",
        "name": "Wedding Venue",
        "category": "Everyday & Unusual",
        "description": "Festive ceremonial hall with floral arches, tiered cake, and champagne toasts.",
        "themes": ["bouquet", "wedding cake", "altar", "toasts", "vows"]
    },
    {
        "id": "prison",
        "name": "Prison",
        "category": "Everyday & Unusual",
        "description": "Maximum security penitentiary with iron bars, watchtowers, and roll calls.",
        "themes": ["iron bars", "warden", "canteen", "handcuffs", "yard"]
    },
    {
        "id": "farm",
        "name": "Farm",
        "category": "Everyday & Unusual",
        "description": "Rural homestead with red barn, tractor, wheat fields, and livestock.",
        "themes": ["tractor", "red barn", "silo", "rooster", "hay bales"]
    },
    {
        "id": "fishing_boat",
        "name": "Fishing Boat",
        "category": "Everyday & Unusual",
        "description": "Seaworthy trawler equipped with heavy drag nets, bait buckets, and compass.",
        "themes": ["nets", "trawler", "fish crates", "sea salt", "deckhands"]
    },
    {
        "id": "lighthouse",
        "name": "Lighthouse",
        "category": "Everyday & Unusual",
        "description": "Towering coastal beacon with revolving fresnel lens, spiral staircase, and rocky surf.",
        "themes": ["fresnel lens", "spiral stairs", "foghorn", "beacon", "rocky cliff"]
    },
    {
        "id": "castle",
        "name": "Castle",
        "category": "Everyday & Unusual",
        "description": "Medieval fortress protected by stone battlements, drawbridge, and moat.",
        "themes": ["drawbridge", "moat", "battlements", "suits of armor", "torches"]
    },
    {
        "id": "desert",
        "name": "Desert",
        "category": "Everyday & Unusual",
        "description": "Sun-scorched expanse of shifting sand dunes, camels, and shimmering mirages.",
        "themes": ["sand dunes", "oasis", "canteen", "mirage", "sun glare"]
    },
    {
        "id": "rainforest",
        "name": "Rainforest",
        "category": "Everyday & Unusual",
        "description": "Dense tropical jungle canopy buzzing with exotic birds, vines, and sudden downpours.",
        "themes": ["canopy", "humidity", "machete", "parrots", "moss"]
    },
    {
        "id": "arctic_research_station",
        "name": "Arctic Research Station",
        "category": "Everyday & Unusual",
        "description": "Isolated polar laboratory surrounded by glaciers, snowmobiles, and sub-zero blizzards.",
        "themes": ["ice cores", "parkas", "snowmobile", "blizzard", "insulated dome"]
    },
    {
        "id": "underwater_facility",
        "name": "Underwater Research Facility",
        "category": "Everyday & Unusual",
        "description": "Deep ocean submersible dome with observation portholes and diving suits.",
        "themes": ["portholes", "sonar", "pressure seals", "oxygen tanks", "submersible"]
    },
    {
        "id": "ancient_temple",
        "name": "Ancient Temple",
        "category": "Everyday & Unusual",
        "description": "Forgotten sacred ruins covered in stone carvings, mossy altars, and torches.",
        "themes": ["altars", "hieroglyphics", "stone pillars", "incense", "relics"]
    },
    {
        "id": "space_observatory",
        "name": "Space Observatory",
        "category": "Everyday & Unusual",
        "description": "High-altitude dome equipped with a giant optical telescope gazing into deep space.",
        "themes": ["telescope", "dome hatch", "star charts", "galaxies", "spectrometer"]
    },
    {
        "id": "royal_palace",
        "name": "Royal Palace",
        "category": "Everyday & Unusual",
        "description": "Grand monarchical residence with crystal chandeliers, velvet thrones, and royal guards.",
        "themes": ["throne", "chandeliers", "royal guards", "red carpet", "crown jewels"]
    },
    {
        "id": "film_set",
        "name": "Film Set",
        "category": "Everyday & Unusual",
        "description": "Movie production soundstage with clapperboards, camera rigs, and makeup mirrors.",
        "themes": ["clapperboard", "director", "script", "makeup trailer", "lights camera action"]
    },
]


def get_all_locations() -> List[Dict[str, Any]]:
    return list(SPYFALL_LOCATIONS)


def get_categories() -> List[str]:
    return list(LOCATION_CATEGORIES)


def get_locations_by_category(category: Optional[str] = None) -> List[Dict[str, Any]]:
    if not category or category.lower() in ("all", "any"):
        return list(SPYFALL_LOCATIONS)
    cat_lower = category.lower().strip()
    return [loc for loc in SPYFALL_LOCATIONS if loc["category"].lower() == cat_lower]


def get_location_names(category: Optional[str] = None) -> List[str]:
    return [loc["name"] for loc in get_locations_by_category(category)]


def normalize_location_name(name: str) -> str:
    """Trims whitespace, lowercases, and removes punctuation for resilient matching."""
    return "".join(ch for ch in name.lower().strip() if ch.isalnum() or ch.isspace())


def match_location_guess(guess: str, actual_location_name: str) -> bool:
    """Exact or canonical match between Spy's guess and the actual location."""
    norm_guess = normalize_location_name(guess)
    norm_actual = normalize_location_name(actual_location_name)
    if not norm_guess:
        return False
    return norm_guess == norm_actual
