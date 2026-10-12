class_name QualityPreset
extends Resource
## One entry of the "Quality" display setting.

@export var display_name: String = ""
@export var msaa_3d: Viewport.MSAA = Viewport.MSAA_DISABLED
@export var screen_space_aa: Viewport.ScreenSpaceAA = Viewport.SCREEN_SPACE_AA_DISABLED
@export var use_taa: bool = false
@export_range(256, 16384, 256, "suffix:px") var directional_shadow_size: int = 4096
