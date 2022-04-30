# Description

This Lua script provides hotkeys to add a source into current scene.

# Properties

## Number of sources
Set number of hotkeys to create source.

## Source
Set properties for the hotkey. This group is available for each hotkey.

### Source name
Set name of the source.

### Bounds type
Set bounds type.
If set to `None`, the source will be added at 100% size.
If set to different bounds type, bounds will be set to the size of the scene.

These types are available.
- `None`
- `Stretch`
- `Scale inner`
- `Scale outer`
- `Scale to width`
- `Scale to height`
- `Max only`

### Blending type
Set blending type. These types are available.
- `Normal`
- `Additive`
- `Subtract`
- `Screen`
- `Multiply`
- `Lighten`
- `Darken`
