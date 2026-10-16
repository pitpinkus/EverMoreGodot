class_name BattleTypes
extends RefCounted
## Enums shared by battle data, battle logic and the overworld (items, encounters).

enum Stat { HP, ATTACK, DEFENSE, SPEED, CRIT_RATE, CRIT_MOD, DODGE }
## NEUTRAL is for moves without an element (Tackle, Growl, ...).
enum Element { FIRE, WATER, WIND, GRASS, ELECTRIC, NEUTRAL }
enum TargetKind { SELF, ENEMY, ALLY }
enum Side { PLAYER, ENEMY }
enum Outcome { WON, LOST, FLED, CAPTURED }

## Player-facing stat names, used in battle messages.
const STAT_NAMES: Dictionary[Stat, String] = {
	Stat.HP: "HP",
	Stat.ATTACK: "Attack",
	Stat.DEFENSE: "Defense",
	Stat.SPEED: "Speed",
	Stat.CRIT_RATE: "Crit Rate",
	Stat.CRIT_MOD: "Crit Power",
	Stat.DODGE: "Dodge",
}

## Short stat names for tight spots (floating numbers, badges).
const STAT_ABBREVIATIONS: Dictionary[Stat, String] = {
	Stat.HP: "HP",
	Stat.ATTACK: "ATK",
	Stat.DEFENSE: "DEF",
	Stat.SPEED: "SPD",
	Stat.CRIT_RATE: "CRT",
	Stat.CRIT_MOD: "CRM",
	Stat.DODGE: "DGE",
}


static func get_stat_name(stat: Stat) -> String:
	return STAT_NAMES.get(stat, "")


static func get_stat_abbreviation(stat: Stat) -> String:
	return STAT_ABBREVIATIONS.get(stat, "")
