import json
import socket
from pathlib import Path


HOST = "127.0.0.1"
PORT = 9876


def send_command(command):
    payload = json.dumps(command).encode("utf-8")
    with socket.create_connection((HOST, PORT), timeout=10) as sock:
        sock.sendall(payload)
        data = sock.recv(1024 * 1024)
    return json.loads(data.decode("utf-8"))


def main():
    root = Path(__file__).resolve().parents[1]
    asset_dir = root / "assets" / "models" / "blender"
    blend_path = asset_dir / "civwar_prop_kit.blend"

    assets = [
        ("watchtower_lowpoly", asset_dir / "watchtower_lowpoly.glb"),
        ("alliance_banner_lowpoly", asset_dir / "alliance_banner_lowpoly.glb"),
        ("relic_obelisk_lowpoly", asset_dir / "relic_obelisk_lowpoly.glb"),
        ("market_stall_lowpoly", asset_dir / "market_stall_lowpoly.glb"),
        ("iron_mine_lowpoly", asset_dir / "iron_mine_lowpoly.glb"),
    ]

    blend_path_text = str(blend_path)

    code = f"""
import bpy
from pathlib import Path

for obj in list(bpy.context.scene.objects):
    obj.select_set(True)
bpy.ops.object.delete()

assets = {json.dumps([(name, str(path)) for name, path in assets])}
spacing = 4.8

for index, (asset_name, filepath) in enumerate(assets):
    before = set(bpy.data.objects)
    bpy.ops.import_scene.gltf(filepath=filepath)
    imported = list(set(bpy.data.objects) - before)
    roots = [obj for obj in imported if obj.parent is None]
    offset_x = (index - (len(assets) - 1) / 2) * spacing

    for obj in imported:
        obj.name = f"CIVWAR_{{asset_name}}_{{obj.name}}"
        if obj.parent is None:
            obj.location.x += offset_x
            obj.location.y += 0

    empty = bpy.data.objects.new(f"CIVWAR_ASSET_ROOT_{{asset_name}}", None)
    bpy.context.collection.objects.link(empty)
    empty.location.x = offset_x
    for root_obj in roots:
        root_obj.parent = empty

bpy.ops.mesh.primitive_plane_add(size=28, location=(0, 0, -0.03))
ground = bpy.context.object
ground.name = "CIVWAR_preview_ground"
mat = bpy.data.materials.new("CIVWAR_preview_ground_mat")
mat.diffuse_color = (0.20, 0.35, 0.24, 1)
ground.data.materials.append(mat)

bpy.ops.object.light_add(type="AREA", location=(0, -7, 8))
light = bpy.context.object
light.name = "CIVWAR_key_area_light"
light.data.energy = 650
light.data.size = 7

bpy.ops.object.camera_add(location=(0, -13, 6), rotation=(1.12, 0, 0))
bpy.context.scene.camera = bpy.context.object

bpy.ops.wm.save_as_mainfile(filepath={json.dumps(blend_path_text)})
print("CIVWAR_BLENDER_MCP: prop kit saved to " + {json.dumps(blend_path_text)})
"""

    response = send_command({"type": "execute_code", "params": {"code": code}})
    print(json.dumps(response, indent=2))


if __name__ == "__main__":
    main()
