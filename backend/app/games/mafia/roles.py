"""Mafia / Werewolf Role Definitions & Distribution Registry for PlayNed.

Scalable and extensible role system supporting 5 to 12 players.
Factions: Town, Mafia, Neutral.
"""

from enum import Enum
from typing import Dict, List, Optional, Any
import random


class Faction(str, Enum):
    TOWN = "town"
    MAFIA = "mafia"
    NEUTRAL = "neutral"


class RoleType(str, Enum):
    VILLAGER = "villager"
    DOCTOR = "doctor"
    DETECTIVE = "detective"
    MAFIA = "mafia"
    BODYGUARD = "bodyguard"
    JESTER = "jester"


class RoleDefinition:
    def __init__(
        self,
        role_type: RoleType,
        name: str,
        faction: Faction,
        description: str,
        night_action_description: Optional[str] = None,
        has_night_action: bool = False,
        is_optional: bool = False,
    ):
        self.role_type = role_type
        self.name = name
        self.faction = faction
        self.description = description
        self.night_action_description = night_action_description
        self.has_night_action = has_night_action
        self.is_optional = is_optional

    def to_dict(self) -> Dict[str, Any]:
        return {
            "role_type": self.role_type.value,
            "name": self.name,
            "faction": self.faction.value,
            "description": self.description,
            "night_action_description": self.night_action_description,
            "has_night_action": self.has_night_action,
            "is_optional": self.is_optional,
        }


# Centralized Role Registry
ROLE_REGISTRY: Dict[RoleType, RoleDefinition] = {
    RoleType.VILLAGER: RoleDefinition(
        role_type=RoleType.VILLAGER,
        name="Villager",
        faction=Faction.TOWN,
        description="An ordinary citizen of the town. Has no special night action. You must rely on observation, discussion, and your vote to root out the Mafia.",
        night_action_description=None,
        has_night_action=False,
        is_optional=False,
    ),
    RoleType.DOCTOR: RoleDefinition(
        role_type=RoleType.DOCTOR,
        name="Doctor",
        faction=Faction.TOWN,
        description="The town medic. Each night, you select one living player to protect from elimination. If the Mafia attacks your patient, they will survive.",
        night_action_description="Choose a living townsperson to protect tonight.",
        has_night_action=True,
        is_optional=False,
    ),
    RoleType.DETECTIVE: RoleDefinition(
        role_type=RoleType.DETECTIVE,
        name="Detective",
        faction=Faction.TOWN,
        description="The town investigator. Each night, you select one living player to investigate. You learn privately whether they are a member of the Mafia.",
        night_action_description="Choose a suspect to investigate for Mafia affiliation.",
        has_night_action=True,
        is_optional=False,
    ),
    RoleType.MAFIA: RoleDefinition(
        role_type=RoleType.MAFIA,
        name="Mafia",
        faction=Faction.MAFIA,
        description="A member of the secret syndicate. You know who your fellow Mafia members are. Each night, you secretly coordinate to eliminate one townsperson.",
        night_action_description="Coordinate with fellow Mafia members and choose a target to eliminate.",
        has_night_action=True,
        is_optional=False,
    ),
    RoleType.BODYGUARD: RoleDefinition(
        role_type=RoleType.BODYGUARD,
        name="Bodyguard",
        faction=Faction.TOWN,
        description="An armed protector. Guards a player each night. If that player is attacked, the bodyguard intercepts the attack.",
        night_action_description="Choose a player to guard with your life.",
        has_night_action=True,
        is_optional=True,
    ),
    RoleType.JESTER: RoleDefinition(
        role_type=RoleType.JESTER,
        name="Jester",
        faction=Faction.NEUTRAL,
        description="An eccentric rogue. You belong to neither Town nor Mafia. Your sole goal is to act suspicious enough to get voted out during the day trial!",
        night_action_description=None,
        has_night_action=False,
        is_optional=True,
    ),
}


# Standard balanced role distribution table for 5 to 12 players
DEFAULT_ROLE_DISTRIBUTION: Dict[int, Dict[RoleType, int]] = {
    5: {RoleType.MAFIA: 1, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 2},
    6: {RoleType.MAFIA: 2, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 2},
    7: {RoleType.MAFIA: 2, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 3},
    8: {RoleType.MAFIA: 2, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 4},
    9: {RoleType.MAFIA: 2, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 5},
    10: {RoleType.MAFIA: 3, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 5},
    11: {RoleType.MAFIA: 3, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 6},
    12: {RoleType.MAFIA: 3, RoleType.DOCTOR: 1, RoleType.DETECTIVE: 1, RoleType.VILLAGER: 7},
}


def get_role_distribution(player_count: int, include_jester: bool = False, include_bodyguard: bool = False) -> List[RoleType]:
    """Generates the list of RoleTypes for a given player count (5-12)."""
    if player_count < 5 or player_count > 12:
        raise ValueError(f"Mafia requires between 5 and 12 players, got {player_count}")

    counts = dict(DEFAULT_ROLE_DISTRIBUTION[player_count])

    # Optional role replacements (swap with Villagers if enabled)
    if include_jester and counts[RoleType.VILLAGER] > 1:
        counts[RoleType.VILLAGER] -= 1
        counts[RoleType.JESTER] = 1

    if include_bodyguard and counts[RoleType.VILLAGER] > 1:
        counts[RoleType.VILLAGER] -= 1
        counts[RoleType.BODYGUARD] = 1

    roles: List[RoleType] = []
    for r_type, count in counts.items():
        roles.extend([r_type] * count)

    if len(roles) != player_count:
        raise ValueError(f"Role distribution count ({len(roles)}) mismatch with player count ({player_count})")

    return roles


def assign_roles(player_ids: List[str], seed: Optional[int] = None, include_jester: bool = False, include_bodyguard: bool = False) -> Dict[str, str]:
    """Fairly distributes roles among player IDs and returns a mapping {player_id: role_type_str}."""
    player_count = len(player_ids)
    role_types = get_role_distribution(player_count, include_jester=include_jester, include_bodyguard=include_bodyguard)

    rng = random.Random(seed) if seed is not None else random.Random()
    shuffled_roles = list(role_types)
    rng.shuffle(shuffled_roles)

    return {pid: role.value for pid, role in zip(player_ids, shuffled_roles)}
