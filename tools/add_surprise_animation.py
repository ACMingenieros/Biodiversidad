"""Add the supplied Mixamo surprise action to the already-textured GLB."""

import bpy
import sys
from mathutils import Quaternion

source_glb, surprise_fbx, output_glb = sys.argv[sys.argv.index('--') + 1:]

bpy.ops.import_scene.gltf(filepath=source_glb)
target_rig = next(obj for obj in bpy.data.objects if obj.type == 'ARMATURE')
old_objects = set(bpy.data.objects)
print('ORIGINAL_OBJECTS', [(obj.name, obj.type) for obj in old_objects])
old_actions = set(bpy.data.actions)
for action in old_actions:
    action.use_fake_user = True

bpy.ops.import_scene.fbx(filepath=surprise_fbx)
fbx_objects = set(bpy.data.objects) - old_objects
print('FBX_OBJECTS', [(obj.name, obj.type) for obj in fbx_objects])
fbx_actions = set(bpy.data.actions) - old_actions
assert len(fbx_actions) == 1, f'Expected one FBX action, found {len(fbx_actions)}'
fbx_rig = next(obj for obj in fbx_objects if obj.type == 'ARMATURE')
assert {b.name for b in fbx_rig.data.bones} == {b.name for b in target_rig.data.bones}
rest_delta = max(
    max(abs(a - b) for row_a, row_b in zip(
        target_rig.data.bones[bone.name].matrix_local,
        bone.matrix_local,
    ) for a, b in zip(row_a, row_b))
    for bone in fbx_rig.data.bones
)
print('MAX_REST_MATRIX_DELTA', rest_delta)

surprise = fbx_actions.pop()
surprise.name = '11_Sorpresa'
surprise.use_fake_user = True

bpy.ops.object.select_all(action='DESELECT')
for obj in fbx_objects:
    obj.select_set(True)
bpy.ops.object.delete(use_global=False)

target_rig.animation_data_create()
target_rig.animation_data.action = None
bpy.context.scene.render.fps = 30
breathing_bones = {
    'Spine': (1.0, 0.0, 0.0, 0.012),
    'neck': (1.0, 0.0, 0.0, -0.006),
}
for bone_name, (axis_x, axis_y, axis_z, angle) in breathing_bones.items():
    bone = target_rig.pose.bones[bone_name]
    bone.rotation_mode = 'QUATERNION'
    base = bone.rotation_quaternion.copy()
    for frame, amount in ((1, 0.0), (31, angle), (61, 0.0)):
        bone.rotation_quaternion = base @ Quaternion((axis_x, axis_y, axis_z), amount)
        bone.keyframe_insert(data_path='rotation_quaternion', frame=frame)
    bone.rotation_quaternion = base
idle = target_rig.animation_data.action
assert idle is not None
idle.name = '01_Reposo'
idle.use_fake_user = True
target_rig.animation_data.action = idle

bpy.ops.object.select_all(action='DESELECT')
target_rig.select_set(True)
next(obj for obj in bpy.data.objects if obj.name == 'char1').select_set(True)

bpy.ops.export_scene.gltf(
    filepath=output_glb,
    export_format='GLB',
    export_animations=True,
    export_animation_mode='BROADCAST',
    use_selection=True,
    export_optimize_animation_size=True,
)
print('EXPORTED_ACTIONS', sorted(action.name for action in bpy.data.actions))
