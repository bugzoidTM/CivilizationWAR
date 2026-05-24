import math
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "models" / "blender"
OUT.mkdir(parents=True, exist_ok=True)


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()


def mat(name, color):
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    return material


STONE = mat("warm_stone", (0.62, 0.55, 0.42, 1))
DARK_STONE = mat("dark_stone", (0.28, 0.30, 0.32, 1))
WOOD = mat("campaign_wood", (0.44, 0.28, 0.15, 1))
DARK_WOOD = mat("dark_wood", (0.27, 0.16, 0.10, 1))
FABRIC_RED = mat("war_red_fabric", (0.62, 0.18, 0.14, 1))
FABRIC_BLUE = mat("alliance_blue_fabric", (0.14, 0.28, 0.68, 1))
GOLD = mat("aged_gold", (0.9, 0.65, 0.22, 1))
IRON = mat("iron", (0.45, 0.48, 0.51, 1))
SAND = mat("relic_sand", (0.72, 0.63, 0.42, 1))


def cube(name, loc, scale, material):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    return obj


def cyl(name, loc, radius, depth, material, vertices=8, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return obj


def cone(name, loc, radius1, radius2, depth, material, vertices=4, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cone_add(
        vertices=vertices,
        radius1=radius1,
        radius2=radius2,
        depth=depth,
        location=loc,
        rotation=rotation,
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return obj


def export(name):
    for obj in bpy.context.scene.objects:
        obj.select_set(True)
    path = OUT / f"{name}.glb"
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True)
    bpy.ops.object.select_all(action="DESELECT")
    print(f"exported {path}")


def build_watchtower():
    reset_scene()
    for x in (-1.5, 1.5):
        for y in (-1.5, 1.5):
            cube("leg", (x, y, 2.6), (0.25, 0.25, 5.2), WOOD)
    cube("platform", (0, 0, 5.25), (4.2, 4.2, 0.3), WOOD)
    cube("rail_front", (0, -2, 6), (4.4, 0.2, 1.1), DARK_WOOD)
    cube("rail_back", (0, 2, 6), (4.4, 0.2, 1.1), DARK_WOOD)
    cube("rail_left", (-2, 0, 6), (0.2, 4.4, 1.1), DARK_WOOD)
    cube("rail_right", (2, 0, 6), (0.2, 4.4, 1.1), DARK_WOOD)
    cone("roof", (0, 0, 7.35), 3.0, 0.25, 2.1, DARK_WOOD, vertices=4, rotation=(0, 0, math.radians(45)))
    export("watchtower_lowpoly")


def build_banner():
    reset_scene()
    cyl("pole", (0, 0, 3), 0.08, 6.0, WOOD, vertices=8)
    cube("flag", (0.58, 0, 4.6), (0.1, 1.75, 1.1), FABRIC_BLUE)
    cube("gold_trim", (0.64, 0, 5.2), (0.12, 1.8, 0.12), GOLD)
    cube("stone_base", (0, 0, 0.15), (0.9, 0.9, 0.3), DARK_STONE)
    export("alliance_banner_lowpoly")


def build_relic_obelisk():
    reset_scene()
    cube("base", (0, 0, 0.3), (3.6, 3.6, 0.6), SAND)
    cube("plinth", (0, 0, 0.85), (2.2, 2.2, 0.5), STONE)
    cube("shaft", (0, 0, 3.1), (0.9, 0.9, 4.1), STONE)
    cone("cap", (0, 0, 5.45), 0.72, 0.05, 0.8, GOLD, vertices=4, rotation=(0, 0, math.radians(45)))
    cube("rune", (0, -0.47, 3.2), (0.55, 0.05, 0.12), GOLD)
    export("relic_obelisk_lowpoly")


def build_market_stall():
    reset_scene()
    cube("counter", (0, 0, 0.75), (3.4, 1.3, 1.0), WOOD)
    for x in (-1.55, 1.55):
        for y in (-0.55, 0.55):
            cube("canopy_post", (x, y, 1.95), (0.15, 0.15, 2.5), DARK_WOOD)
    cube("canopy", (0, 0, 3.2), (3.8, 1.8, 0.18), GOLD)
    cube("cloth_red", (-0.75, -0.92, 2.6), (0.9, 0.08, 1.0), FABRIC_RED)
    cube("cloth_blue", (0.75, -0.92, 2.6), (0.9, 0.08, 1.0), FABRIC_BLUE)
    export("market_stall_lowpoly")


def build_mine_marker():
    reset_scene()
    cube("rock_floor", (0, 0, 0.2), (3.8, 3.2, 0.4), DARK_STONE)
    cube("mine_face", (0, 0.9, 1.6), (2.7, 0.8, 2.8), DARK_STONE)
    cube("support", (0, 0.45, 3.0), (3.0, 0.2, 0.25), WOOD)
    cube("ore_vein", (0, 0.48, 2.15), (2.1, 0.12, 0.16), IRON)
    export("iron_mine_lowpoly")


def build_preview_scene():
    reset_scene()
    build_watchtower()
    build_banner()
    build_relic_obelisk()
    build_market_stall()
    build_mine_marker()
    reset_scene()
    build_watchtower()
    bpy.context.object.location.x = -4
    build_banner()
    bpy.context.object.location.x = 1


if __name__ == "__main__":
    build_watchtower()
    build_banner()
    build_relic_obelisk()
    build_market_stall()
    build_mine_marker()
