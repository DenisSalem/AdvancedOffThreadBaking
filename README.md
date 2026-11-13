# Procedure to test related remote commits :

Clone Godot repository then

```
git checkout c51ff06e8 # 4.8-beta-3
git switch -c 4.8-beta-3-threaded-voxel-gi
git remote add TitanNano https://github.com/TitanNano/godot
git fetch TitanNano
```

Cherry-pick in order commits from the original [MR](https://github.com/godotengine/godot/compare/master...TitanNano:godot:jovan/voxel_gi_sub_thread_bake)

```
# Do not copy/past directly, check for the right commits in the original PR

git cherry-pick 7285ca00e7eb7a8c456cb48c964d31eeaef04a64
git cherry-pick 0bd0454766b8d97134a61452152d55010de17bd8
```
compile

```
scons && scons target=template_release && scons target=template_debug
```

# Usage

Export the project then start the application.

```
  Press B - Bake in the main thread (blocking)
  Press O - Bake off the main thread (non-blocking)
  Press C - Bake in a Child process (non-blocking)
  Press I - Interrupt baking (Delete VoxelGI node)
  Press R - Interrupt baking (Renew VoxelGI node)
  Press D - Delete VoxelGI Data
```

__Note__: _Baking in a child process may not work from the editor._
