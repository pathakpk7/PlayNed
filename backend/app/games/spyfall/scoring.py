from typing import Dict, List, Any

SPY_CORRECT_GUESS_POINTS = 3
SPY_SURVIVE_POINTS = 2
SPY_IDENTIFIED_POINTS = 0

NON_SPY_CORRECT_VOTE_POINTS = 2
NON_SPY_SURVIVE_ROUND_POINTS = 1
NON_SPY_FAIL_VOTE_POINTS = 0


def calculate_round_points(
    player_ids: List[str],
    spy_player_id: str,
    outcome: str,
    votes: Dict[str, str],
    accused_target_id: str = None,
) -> Dict[str, int]:
    """
    Computes points awarded to each player for the completed round.
    
    Outcomes:
    - 'SPY_GUESSED_LOCATION': Spy correctly named the location (+3 to Spy, 0 to others).
    - 'SPY_CAUGHT': Accusation successfully identified the Spy, and Spy failed location guess (+2 to voters of Spy, 0 to Spy).
    - 'SPY_SURVIVED_TIME': Timer expired without Spy being identified, and Spy did not guess location (+2 to Spy, +1 to non-spies).
    - 'INNOCENT_ACCUSED': Non-spies accused an innocent player, Spy survives (+2 to Spy, 0 to others).
    """
    points = {pid: 0 for pid in player_ids}

    if outcome == "SPY_GUESSED_LOCATION":
        # Spy takes top prize of 3 points
        points[spy_player_id] = SPY_CORRECT_GUESS_POINTS

    elif outcome == "SPY_CAUGHT":
        # Non-spies who voted to convict the Spy get +2 points
        points[spy_player_id] = SPY_IDENTIFIED_POINTS
        for voter_id, vote_choice in votes.items():
            if voter_id != spy_player_id:
                if vote_choice == "guilty" or vote_choice == spy_player_id:
                    points[voter_id] = NON_SPY_CORRECT_VOTE_POINTS

    elif outcome == "SPY_SURVIVED_TIME":
        # Spy survives: +2 points. Non-spies get +1 for participating.
        points[spy_player_id] = SPY_SURVIVE_POINTS
        for pid in player_ids:
            if pid != spy_player_id:
                points[pid] = NON_SPY_SURVIVE_ROUND_POINTS

    elif outcome == "INNOCENT_ACCUSED":
        # Wrong player was accused; Spy slips away undetected
        points[spy_player_id] = SPY_SURVIVE_POINTS

    return points
