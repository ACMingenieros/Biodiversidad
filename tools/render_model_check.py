"""Render a quick material check for a bundled Ukumari GLB."""

import bpy
import mathutils
import sys

args = sys.argv[sys.argv.index('--') + 1:]
source_glb, output_png, side = args[:3]
extra = args[3:]
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=source_glb)

for obj in list(bpy.data.objects):
    if obj.type in {'CAMERA', 'LIGHT'}:
        bpy.data.objects.remove(obj, do_unlink=True)

rig = next(obj for obj in bpy.data.objects if obj.type == 'ARMATURE')
chosen_action = bpy.data.actions.get(extra[0] if extra else '01_Reposo')
if chosen_action is not None:
    rig.animation_data_create()
    rig.animation_data.action = chosen_action
    bpy.context.scene.frame_set(int(extra[1]) if len(extra) > 1 else 1)

camera_data = bpy.data.cameras.new('ReviewCamera')
camera = bpy.data.objects.new('ReviewCamera', camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (0, -3.6 if side == 'front' else 3.6, 1.45)
target = mathutils.Vector((0, 0, 0.8))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 2.1
bpy.context.scene.camera = camera

for name, location, power in (
    ('Key', (2, -3, 4), 800),
    ('Fill', (-3, -2, 2), 350),
    ('Rim', (1, 3, 3), 650),
):
    lamp_data = bpy.data.lights.new(name, 'AREA')
    lamp = bpy.data.objects.new(name, lamp_data)
    bpy.context.collection.objects.link(lamp)
    lamp.location = location
    lamp.rotation_euler = (target - lamp.location).to_track_quat('-Z', 'Y').to_euler()
    lamp_data.energy = power
    lamp_data.shape = 'DISK'
    lamp_data.size = 3

scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.render.resolution_x = 640
scene.render.resolution_y = 640
scene.render.resolution_percentage = 100
scene.render.film_transparent = len(extra) > 2 and extra[2] == 'transparent'
scene.world.color = (0.8, 0.8, 0.8)
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = output_png
bpy.ops.render.render(write_still=True)
