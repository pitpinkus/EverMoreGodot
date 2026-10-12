class_name SaveConfig
extends Resource
## How SaveSystem writes save files. Loaded from res://data/save/save_config.tres.
## Reading never depends on this: the file extension tells SaveGame how each file
## is encoded, so encrypted and readable saves are always listed and loadable.

## True: encrypted binary files. False: human-readable text files, for checking
## saved data while debugging.
@export var encrypt: bool = true
## Key for encrypted saves. This is anti-tamper obfuscation only, NOT security:
## the password ships inside the game, so anyone can extract it. Changing it makes
## existing encrypted saves unreadable.
@export var encryption_password: String = ""
