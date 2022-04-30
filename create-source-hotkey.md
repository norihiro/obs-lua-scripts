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

# Design note

Implementation items

- [x] Provide a property to select number of hotkeys
- [x] Create hotkeys that can be configured from the settings of OBS
- [x] For each source hotkey, provide these properties.
  - [x] select existing source, not only media source but also other types.
  - [x] bounding box type
  - [x] blending mode
- [x] Everytime the hotkey is triggered, the specified media source will be added to the current scene.
- [x] Multiple presses should create duplicates.
- [ ] TODO items in the code

Spec confirmation
- [ ] If bounding box type is not 'None', need to specify the size of bounding box. What is the prefered bounding box? Canvas?

Limitations

- The script does not support Studio Mode.
