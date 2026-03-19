
# ios_multi_slidable

A highly customizable, iOS-style slidable list item for Flutter with elastic over-scroll, dynamic height calculations, and sequential reveal animations.


## Features

*  Replicates the exact elastic stretch and sequential pop-in animations of iOS swipe actions.
* Swipe left or right to reveal different action sets.

* Built-in haptic feedback when the user crosses the full-swipe threshold.

## example
![demo video](./demo/)

## Getting started

Add this to your package's `pubspec.yaml` file:
    
```yaml
dependencies:
  ios_multi_slidable: ^0.0.1
```
## Usage/Examples

```dart
IosMultiSlidable(
  rightActions: [
    SlidableAction(
      onTap: () {},
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
  ],
  child: ListTile(title: Text('Swipe me left')),
);

```