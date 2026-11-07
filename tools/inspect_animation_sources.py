import bpy
import sys

glb, fbx = sys.argv[sys.argv.index('--') + 1:]

bpy.ops.import_scene.gltf(filepath=glb)
print('GLB_ARMATURES', [(o.name, [b.name for b in o.data.bones]) for o in bpy.data.objects if o.type == 'ARMATURE'])
print('GLB_ACTIONS', [(a.name, int(a.frame_range[0]), int(a.frame_range[1])) for a in bpy.data.actions])

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
for action in list(bpy.data.actions):
    bpy.data.actions.remove(action)

bpy.ops.import_scene.fbx(filepath=fbx)
print('FBX_ARMATURES', [(o.name, [b.name for b in o.data.bones]) for o in bpy.data.objects if o.type == 'ARMATURE'])
print('FBX_ACTIONS', [(a.name, int(a.frame_range[0]), int(a.frame_range[1])) for a in bpy.data.actions])
