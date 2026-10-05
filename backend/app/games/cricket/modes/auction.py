from typing import Dict, Any, List, Optional, Tuple
import random

FICTIONAL_FRANCHISES = [
    {
        "id": "mumbai_mariners",
        "name": "Mumbai Mariners",
        "short_name": "MM",
        "primary_color": "#0D47A1",
        "secondary_color": "#FFD54F",
        "motto": "Duniya Hila Denge",
        "city": "Mumbai"
    },
    {
        "id": "chennai_chargers",
        "name": "Chennai Chargers",
        "short_name": "CC",
        "primary_color": "#FFB300",
        "secondary_color": "#1A237E",
        "motto": "Whistle Podu",
        "city": "Chennai"
    },
    {
        "id": "bengaluru_blazers",
        "name": "Bengaluru Blazers",
        "short_name": "BB",
        "primary_color": "#C62828",
        "secondary_color": "#212121",
        "motto": "Play Bold",
        "city": "Bengaluru"
    },
    {
        "id": "kolkata_knights",
        "name": "Kolkata Knights",
        "short_name": "KK",
        "primary_color": "#4A148C",
        "secondary_color": "#FFD54F",
        "motto": "Korbo Lorbo Jeetbo",
        "city": "Kolkata"
    },
    {
        "id": "hyderabad_hawks",
        "name": "Hyderabad Hawks",
        "short_name": "HH",
        "primary_color": "#E65100",
        "secondary_color": "#212121",
        "motto": "Rise With Us",
        "city": "Hyderabad"
    },
    {
        "id": "rajasthan_royals_x",
        "name": "Rajasthan Royals-X",
        "short_name": "RRX",
        "primary_color": "#C2185B",
        "secondary_color": "#0D47A1",
        "motto": "Halla Bol",
        "city": "Jaipur"
    },
    {
        "id": "punjab_panthers",
        "name": "Punjab Panthers",
        "short_name": "PP",
        "primary_color": "#B71C1C",
        "secondary_color": "#CFD8DC",
        "motto": "Sadda Jazba",
        "city": "Mohali"
    },
    {
        "id": "delhi_dynamos",
        "name": "Delhi Dynamos",
        "short_name": "DD",
        "primary_color": "#0277BD",
        "secondary_color": "#C62828",
        "motto": "Roar Macha",
        "city": "Delhi"
    },
    {
        "id": "gujarat_giants",
        "name": "Gujarat Giants",
        "short_name": "GG",
        "primary_color": "#00695C",
        "secondary_color": "#FF8F00",
        "motto": "Aava De",
        "city": "Ahmedabad"
    },
    {
        "id": "lucknow_leopards",
        "name": "Lucknow Leopards",
        "short_name": "LL",
        "primary_color": "#00838F",
        "secondary_color": "#FF8F00",
        "motto": "Gazab Andaz",
        "city": "Lucknow"
    }
]

ACTIVE_IPL_AUCTION_PLAYERS = [
    {
        "id": "virat_kohli",
        "name": "Virat Kohli",
        "country": "India",
        "role": "Batter",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 97
    },
    {
        "id": "jasprit_bumrah",
        "name": "Jasprit Bumrah",
        "country": "India",
        "role": "Bowler",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 98
    },
    {
        "id": "rohit_sharma",
        "name": "Rohit Sharma",
        "country": "India",
        "role": "Batter",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 94
    },
    {
        "id": "heinrich_klaasen",
        "name": "Heinrich Klaasen",
        "country": "South Africa",
        "role": "Wicketkeeper",
        "is_overseas": True,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 95
    },
    {
        "id": "pat_cummins",
        "name": "Pat Cummins",
        "country": "Australia",
        "role": "All-Rounder",
        "is_overseas": True,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 94
    },
    {
        "id": "mitchell_starc",
        "name": "Mitchell Starc",
        "country": "Australia",
        "role": "Bowler",
        "is_overseas": True,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 93
    },
    {
        "id": "rashid_khan",
        "name": "Rashid Khan",
        "country": "Afghanistan",
        "role": "All-Rounder",
        "is_overseas": True,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 96
    },
    {
        "id": "rishabh_pant",
        "name": "Rishabh Pant",
        "country": "India",
        "role": "Wicketkeeper",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 94
    },
    {
        "id": "shubman_gill",
        "name": "Shubman Gill",
        "country": "India",
        "role": "Batter",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 93
    },
    {
        "id": "travis_head",
        "name": "Travis Head",
        "country": "Australia",
        "role": "Batter",
        "is_overseas": True,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 94
    },
    {
        "id": "andre_russell",
        "name": "Andre Russell",
        "country": "West Indies",
        "role": "All-Rounder",
        "is_overseas": True,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 94
    },
    {
        "id": "suryakumar_yadav",
        "name": "Suryakumar Yadav",
        "country": "India",
        "role": "Batter",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 96
    },
    {
        "id": "ms_dhoni",
        "name": "MS Dhoni",
        "country": "India",
        "role": "Wicketkeeper",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 96
    },
    {
        "id": "shreyas_iyer",
        "name": "Shreyas Iyer",
        "country": "India",
        "role": "Batter",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 93
    },
    {
        "id": "ishan_kishan",
        "name": "Ishan Kishan",
        "country": "India",
        "role": "Wicketkeeper",
        "is_overseas": False,
        "is_marquee": True,
        "base_price": 2.0,
        "overall_rating": 91
    },
    {
        "id": "ravindra_jadeja",
        "name": "Ravindra Jadeja",
        "country": "India",
        "role": "All-Rounder",
        "is_overseas": False,
        "is_marquee": False,
        "base_price": 2.0,
        "overall_rating": 93
    },
    {
        "id": "sunil_narine",
        "name": "Sunil Narine",
        "country": "West Indies",
        "role": "All-Rounder",
        "is_overseas": True,
        "is_marquee": False,
        "base_price": 2.0,
        "overall_rating": 94
    },
    {
        "id": "arshdeep_singh",
        "name": "Arshdeep Singh",
        "country": "India",
        "role": "Bowler",
        "is_overseas": False,
        "is_marquee": False,
        "base_price": 2.0,
        "overall_rating": 92
    },
    {
        "id": "varun_chakravarthy",
        "name": "Varun Chakravarthy",
        "country": "India",
        "role": "Bowler",
        "is_overseas": False,
        "is_marquee": False,
        "base_price": 2.0,
        "overall_rating": 92
    },
    {
        "id": "kuldeep_yadav",
        "name": "Kuldeep Yadav",
        "country": "India",
        "role": "Bowler",
        "is_overseas": False,
        "is_marquee": False,
        "base_price": 2.0,
        "overall_rating": 92
    },
    {
        "id": "shashank_singh",
        "name": "Shashank Singh",
        "country": "India",
        "role": "Batter",
        "is_overseas": False,
        "is_marquee": False,
        "base_price": 0.3,
        "overall_rating": 86
    },
    {
        "id": "mayank_yadav",
        "name": "Mayank Yadav",
        "country": "India",
        "role": "Bowler",
        "is_overseas": False,
        "is_marquee": False,
        "base_price": 1.5,
        "overall_rating": 89
    }
]

class CricketAuctionBackendEngine:
    """
    PlayNed Cricket Hub IPL Mini Auction Backend Engine.
    Handles franchise state, purse constraints, marquee draft, retentions, and live bidding.
    """

    def create_initial_state(self, player_ids: List[str], player_names: Dict[str, str], options: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        options = options or {}
        
        # Build 10 franchises
        franchises: Dict[str, Dict[str, Any]] = {}
        for i, f in enumerate(FICTIONAL_FRANCHISES):
            f_id = f["id"]
            owner_player_id = player_ids[i] if i < len(player_ids) else None
            is_ai = (owner_player_id is None)
            franchises[f_id] = {
                "id": f_id,
                "name": f["name"],
                "short_name": f["short_name"],
                "owner_id": owner_player_id,
                "is_ai": is_ai,
                "purse_remaining": 120.0,
                "squad": [],
                "retentions": [],
                "overseas_count": 0
            }

        marquee_pool = [p for p in ACTIVE_IPL_AUCTION_PLAYERS if p.get("is_marquee", False)]
        auction_queue = [p for p in ACTIVE_IPL_AUCTION_PLAYERS if not p.get("is_marquee", False)]

        return {
            "mode_id": "auction",
            "phase": "marquee_draft", # marquee_draft, retention, live_auction, completed
            "franchises": franchises,
            "marquee_pool": marquee_pool,
            "auction_queue": auction_queue,
            "current_lot": None,
            "current_bid": 0.0,
            "current_bidder_team_id": None,
            "hammer_stage": 0,
            "sold_players": [],
            "unsold_players": [],
            "activity_feed": ["IPL Mini Auction Room Initialized. ₹120.0 Cr Purse available."]
        }

    def _get_next_increment(self, current_bid: float) -> float:
        if current_bid < 1.0:
            return 0.20
        elif current_bid < 2.0:
            return 0.25
        elif current_bid < 5.0:
            return 0.50
        elif current_bid < 10.0:
            return 0.50
        else:
            return 1.00

    def validate_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
        action = move.get("action")
        team_id = move.get("team_id")
        franchises = state.get("franchises", {})
        
        if team_id not in franchises:
            return False, f"Invalid team_id: {team_id}"

        team = franchises[team_id]

        if action == "select_marquee":
            player_id_target = move.get("player_id")
            if state.get("phase") != "marquee_draft":
                return False, "Not in marquee draft phase"
            if len(team.get("squad", [])) > 0:
                return False, "Marquee player already selected"
            return True, None

        elif action == "place_bid":
            if state.get("phase") not in ("live_auction", "accelerated"):
                return False, "Not in live auction phase"
            current_lot = state.get("current_lot")
            if not current_lot:
                return False, "No active player lot in auction"
            if state.get("current_bidder_team_id") == team_id:
                return False, "Already the highest bidder"

            # Check overseas cap
            is_overseas = current_lot.get("is_overseas", False)
            if is_overseas and team.get("overseas_count", 0) >= 8:
                return False, "Overseas player limit (8) reached"

            # Check squad size
            if len(team.get("squad", [])) >= 25:
                return False, "Maximum squad size (25) reached"

            # Check purse
            curr_bid = state.get("current_bid", 0.0)
            next_bid = curr_bid + self._get_next_increment(curr_bid) if state.get("current_bidder_team_id") else current_lot.get("base_price", 0.20)
            
            slots_needed = max(0, 18 - (len(team.get("squad", [])) + 1))
            reserve_needed = slots_needed * 0.20
            if (team["purse_remaining"] - next_bid) < reserve_needed:
                return False, "Insufficient purse (must reserve ₹0.20 Cr for remaining squad slots)"

            return True, None

        elif action == "pass":
            return True, None

        return True, None

    def apply_move(self, state: Dict[str, Any], player_id: str, move: Dict[str, Any]) -> Dict[str, Any]:
        action = move.get("action")
        team_id = move.get("team_id")
        franchises = state["franchises"]
        team = franchises.get(team_id)

        if action == "select_marquee":
            target_pid = move.get("player_id")
            pool = state["marquee_pool"]
            chosen = next((p for p in pool if p["id"] == target_pid), None)
            if chosen and team:
                price = 18.0
                team["purse_remaining"] -= price
                team["squad"].append({**chosen, "sold_price": price})
                team["retentions"].append(chosen)
                if chosen.get("is_overseas"):
                    team["overseas_count"] += 1
                state["sold_players"].append(chosen)
                state["marquee_pool"] = [p for p in pool if p["id"] != target_pid]
                state["activity_feed"].insert(0, f"{team['name']} drafted Marquee Icon: {chosen['name']} (₹18.0 Cr)")
                
                # Check if marquee phase finished
                if len(state["marquee_pool"]) == 0 or all(len(f["squad"]) > 0 for f in franchises.values()):
                    state["phase"] = "live_auction"
                    self._start_next_lot(state)

        elif action == "place_bid":
            current_lot = state["current_lot"]
            curr_bid = state["current_bid"]
            if not state.get("current_bidder_team_id"):
                next_bid = current_lot["base_price"]
            else:
                next_bid = curr_bid + self._get_next_increment(curr_bid)

            state["current_bid"] = next_bid
            state["current_bidder_team_id"] = team_id
            state["hammer_stage"] = 0
            state["activity_feed"].insert(0, f"BID: {team['name']} bids ₹{next_bid:.2f} Cr on {current_lot['name']}")

        elif action == "tick_timer":
            stage = state.get("hammer_stage", 0) + 1
            state["hammer_stage"] = stage
            current_lot = state.get("current_lot")
            bidder_id = state.get("current_bidder_team_id")

            if stage == 1:
                state["activity_feed"].insert(0, f"Going ONCE at ₹{state['current_bid']:.2f} Cr...")
            elif stage == 2:
                state["activity_feed"].insert(0, f"Going TWICE at ₹{state['current_bid']:.2f} Cr...")
            elif stage >= 3:
                # SOLD or UNSOLD
                if bidder_id and current_lot:
                    winner = franchises[bidder_id]
                    final_price = state["current_bid"]
                    winner["purse_remaining"] -= final_price
                    winner["squad"].append({**current_lot, "sold_price": final_price})
                    if current_lot.get("is_overseas"):
                        winner["overseas_count"] += 1
                    state["sold_players"].append(current_lot)
                    state["activity_feed"].insert(0, f"SOLD! 🔨 {current_lot['name']} to {winner['name']} for ₹{final_price:.2f} Cr!")
                elif current_lot:
                    state["unsold_players"].append(current_lot)
                    state["activity_feed"].insert(0, f"UNSOLD: {current_lot['name']}")

                self._start_next_lot(state)

        return state

    def _start_next_lot(self, state: Dict[str, Any]):
        queue = state.get("auction_queue", [])
        if queue:
            lot = queue.pop(0)
            state["current_lot"] = lot
            state["current_bid"] = lot.get("base_price", 0.20)
            state["current_bidder_team_id"] = None
            state["hammer_stage"] = 0
            state["activity_feed"].insert(0, f"Next Lot: {lot['name']} (Base ₹{state['current_bid']:.2f} Cr)")
        else:
            state["current_lot"] = None
            state["phase"] = "completed"
            state["activity_feed"].insert(0, "IPL Mini Auction Concluded!")

    def get_available_moves(self, state: Dict[str, Any], player_id: str) -> List[Dict[str, Any]]:
        phase = state.get("phase")
        if phase == "marquee_draft":
            return [{"action": "select_marquee"}]
        elif phase in ("live_auction", "accelerated"):
            return [{"action": "place_bid"}, {"action": "pass"}, {"action": "tick_timer"}]
        return []
