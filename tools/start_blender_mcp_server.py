import bpy


def main():
    try:
        bpy.ops.preferences.addon_enable(module="addon")
    except Exception as exc:
        print(f"BlenderMCP addon enable warning: {exc}")

    scene = bpy.context.scene
    scene.blendermcp_port = 9876

    if not scene.blendermcp_server_running:
        bpy.ops.blendermcp.start_server()

    print(f"CIVWAR_BLENDER_MCP: listening on localhost:{scene.blendermcp_port}")


main()
