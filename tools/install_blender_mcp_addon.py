import bpy
import pathlib

addon_path = pathlib.Path(__file__).resolve().parents[1] / ".tools" / "blender-mcp" / "addon.py"

bpy.ops.preferences.addon_install(filepath=str(addon_path), overwrite=True)
bpy.ops.preferences.addon_enable(module="addon")
bpy.ops.wm.save_userpref()

print(f"Installed BlenderMCP addon from {addon_path}")
