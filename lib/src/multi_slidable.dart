import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ios_multi_slidable/ios_multi_slidable.dart';

/// A highly customizable, iOS-style slidable list item with elastic over-scroll,
/// dynamic height calculations, and sequential scale/fade animations.
///
/// This widget automatically sizes its action buttons to match the exact height
/// of the [child] provided, ensuring perfect circles when resting and smooth
/// stadium/pill shapes when elastically stretched.
class IosMultiSlidable extends StatefulWidget {
  /// The primary content of the list item.
  /// Typically a [ListTile] or a custom container.
  final Widget child;

  /// The background color of the sliding tile.
  /// Prevents visual bleeding if the [child] has a transparent background.
  final Color? tileColor;

  /// A list of [SlidableAction]s revealed by swiping from right to left.
  final List<SlidableAction> rightActions;

  /// A list of [SlidableAction]s revealed by swiping from left to right.
  final List<SlidableAction>? leftActions;

  // --- BEHAVIOR ---

  /// The fraction of the screen width required to trigger a full swipe action.
  ///
  /// For example, `0.65` means the user must swipe across 65% of the total
  /// width to trigger the final edge action.
  /// Defaults to `0.65`.
  final double fullSwipeFraction;

  /// Whether to trigger a medium impact haptic vibration when the user drags
  /// past the [fullSwipeFraction] threshold.
  /// Defaults to `true`.
  final bool enableHaptics;

  /// If `true`, dragging past the [fullSwipeFraction] and releasing will
  /// automatically trigger the `onTap` function of the outermost action.
  /// Defaults to `true`.
  final bool swipeToTriggerEdgeAction;

  /// If `true`, the slidable will automatically close after any action is tapped.
  /// Defaults to `true`.
  final bool closeOnActionTap;

  // --- VISUALS ---

  /// The horizontal spacing in pixels between multiple actions.
  /// Defaults to `8.0`.
  final double actionSpacing;

  /// The border radius applied to the action buttons.
  /// Defaults to `100` (a perfect circle/stadium shape).
  final BorderRadius actionBorderRadius;

  /// How many pixels before the tile completely covers the button should it
  /// reach a scale of 0.0.
  ///
  /// Increasing this makes the button disappear earlier as the tile slides over it.
  /// Defaults to `40.0`.
  final double earlyShrinkOffset;

  /// The visual distance (in pixels) the edge button physically "pops" outward
  /// to indicate to the user that the full-swipe threshold has been crossed.
  /// Defaults to `35.0`.
  final double pushDistance;

  // --- ANIMATIONS ---

  /// The duration of the smooth snap-open and snap-close animations.
  /// Defaults to `300` milliseconds.
  final Duration snapDuration;

  /// The duration of the elastic pop/push animation when crossing the full swipe threshold.
  /// Defaults to `150` milliseconds.
  final Duration pushDuration;

  final bool closeOthersOnOpen;

  /// Creates an [IosMultiSlidable] widget.
  const IosMultiSlidable({
    super.key,
    required this.child,
    this.tileColor,
    required this.rightActions,
    this.leftActions,
    this.fullSwipeFraction = 0.55,
    this.enableHaptics = true,
    this.swipeToTriggerEdgeAction = true,
    this.closeOnActionTap = true,
    this.actionSpacing = 8.0,
    this.actionBorderRadius = const BorderRadius.all(Radius.circular(100)),
    this.earlyShrinkOffset = 40.0,
    this.pushDistance = 35.0,
    this.snapDuration = const Duration(milliseconds: 600),
    this.pushDuration = const Duration(milliseconds: 150),
    this.closeOthersOnOpen = true,
  });

  @override
  State<IosMultiSlidable> createState() => _IosMultiSlidableState();
}

class _IosMultiSlidableState extends State<IosMultiSlidable>
    with TickerProviderStateMixin {
  static final Set<_IosMultiSlidableState> activeSlidables = {};
  late AnimationController snapController;
  Animation<double>? snapAnimation;

  late AnimationController pushController;
  late Animation<double> pushAnimation;

  double swipeAmount = 0.0;

  /// Calculates the physical pixel limit required to trigger a full swipe.
  double get fullSwipeThresholdLimit =>
      MediaQuery.of(context).size.width * widget.fullSwipeFraction;

  bool hasTriggeredHaptic = false;

  /// Tracks the real-time height of the child widget to calculate perfectly round buttons.
  double dynamicTileHeight = 56.0;

  /// Action buttons are perfectly square initially, so width equals height.
  double get buttonSize => dynamicTileHeight;

  /// Calculates the total width required to fully reveal all active actions.
  double get totalActionsWidth {
    final bool isLeftAction = swipeAmount > 0;
    final List<SlidableAction> currentList =
        isLeftAction ? (widget.leftActions ?? []) : widget.rightActions;

    if (currentList.isEmpty) return 0.0;
    final count = currentList.length;

    return (buttonSize * count) + (widget.actionSpacing * (count));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This safely looks up the widget tree for the group controller
  }

  @override
  void initState() {
    super.initState();

    snapController =
        AnimationController(vsync: this, duration: widget.snapDuration)
          ..addListener(() {
            if (snapAnimation != null) {
              setState(() {
                swipeAmount = snapAnimation!.value;
                if (swipeAmount == 0) {
                  activeSlidables.remove(this);
                } else {
                  activeSlidables.add(this);
                }
              });
            }
          });

    pushController =
        AnimationController(vsync: this, duration: widget.pushDuration)
          ..addListener(() {
            setState(() {});
          });

    pushAnimation = Tween<double>(begin: 0.0, end: widget.pushDistance).animate(
      CurvedAnimation(parent: pushController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    activeSlidables.remove(this);
    snapController.dispose();
    pushController.dispose();
    super.dispose();
  }

  void onDragUpdate(DragUpdateDetails details) {
    if (widget.closeOthersOnOpen && swipeAmount == 0) {
      for (final other in activeSlidables.toList()) {
        if (other != this && other.mounted) {
          other.closeSlidable();
        }
      }
    }
    setState(() {
      swipeAmount += details.delta.dx;

      // Restrict sliding in a direction if no actions are provided
      if ((widget.leftActions == null || widget.leftActions!.isEmpty) &&
          swipeAmount > 0) {
        swipeAmount = 0;
      }
      if (widget.rightActions.isEmpty && swipeAmount < 0) {
        swipeAmount = 0;
      }

      final double absSwipe = swipeAmount.abs();

      // Handle the physical "pop" and haptics when crossing the threshold
      if (absSwipe > fullSwipeThresholdLimit && !hasTriggeredHaptic) {
        if (widget.enableHaptics) HapticFeedback.mediumImpact();
        hasTriggeredHaptic = true;
        pushController.forward();
      } else if (absSwipe <= fullSwipeThresholdLimit && hasTriggeredHaptic) {
        hasTriggeredHaptic = false;
        pushController.reverse();
      }
      if (swipeAmount != 0) {
        activeSlidables.add(this);
      }
    });
  }

  void onDragEnd(DragEndDetails details) {
    final double absSwipe = swipeAmount.abs();

    final bool isLeftAction = swipeAmount > 0;
    final List<SlidableAction> currentList =
        isLeftAction ? (widget.leftActions ?? []) : widget.rightActions;

    // Check if the user swiped far enough to trigger the edge action automatically
    if (absSwipe > fullSwipeThresholdLimit && widget.swipeToTriggerEdgeAction) {
      if (currentList.isNotEmpty) {
        if (isLeftAction) {
          currentList.first.onTap();
        } else {
          currentList.last.onTap();
        }
      }
      closeSlidable();
      return;
    }

    // Determine if it should snap open or snap closed based on drag distance
    final double target =
        absSwipe >= (totalActionsWidth / 2) ? totalActionsWidth : 0.0;

    // Maintain the correct directional sign
    final double finalTarget = isLeftAction ? target : -target;

    snapAnimation = Tween<double>(begin: swipeAmount, end: finalTarget).animate(
      CurvedAnimation(parent: snapController, curve: Curves.easeOutCubic),
    );
    snapController.forward(from: 0.0);
  }

  void closeSlidable() {
    if (swipeAmount == 0) return;
    pushController.reverse();
    hasTriggeredHaptic = false;

    snapAnimation = Tween<double>(
      begin: swipeAmount,
      end: 0.0,
    ).animate(CurvedAnimation(parent: snapController, curve: Curves.easeOut));
    snapController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLeftAction = swipeAmount > 0;
    final List<SlidableAction> currentActions =
        isLeftAction ? (widget.leftActions ?? []) : widget.rightActions;

    final double absSwipe = swipeAmount.abs();
    final double displaySwipeAmount = absSwipe + pushAnimation.value;

    return GestureDetector(
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      child: Stack(
        children: [
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double measuredHeight = constraints.maxHeight;

                // Dynamically update tile height if it changes
                if (measuredHeight != dynamicTileHeight) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && measuredHeight != dynamicTileHeight) {
                      setState(() => dynamicTileHeight = measuredHeight);
                    }
                  });
                }

                // Buttons are sized to slightly smaller than the full tile height
                final double buttonSize = measuredHeight - 4.0;
                final double displaySwipe = absSwipe + pushAnimation.value;

                // Extra space drives the elastic stadium stretching
                final double extraSpace = displaySwipe > totalActionsWidth
                    ? displaySwipe - totalActionsWidth
                    : 0.0;

                return Align(
                  alignment: isLeftAction
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: SizedBox(
                    width: displaySwipe,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: !isLeftAction,
                      child: Row(
                        mainAxisAlignment: isLeftAction
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: currentActions.asMap().entries.map((entry) {
                          final int index = entry.key;
                          final SlidableAction action = entry.value;

                          // The edge action is the one that stretches elastically
                          final bool isEdge = isLeftAction
                              ? index == 0
                              : index == currentActions.length - 1;

                          double currentWidth = buttonSize;
                          if (isEdge) currentWidth += extraSpace;

                          // Control the icon sliding to the edge during an over-drag
                          Alignment iconAlignment = Alignment.center;
                          if (isEdge && absSwipe > fullSwipeThresholdLimit) {
                            iconAlignment = isLeftAction
                                ? const Alignment(1.0, 0.0)
                                : const Alignment(-1.0, 0.0);
                          }

                          // Find this button's position relative to the moving edge
                          final int positionFromAnchor = isLeftAction
                              ? index
                              : (currentActions.length - 1 - index);

                          final double itemTotalWidth =
                              buttonSize + widget.actionSpacing;
                          final double startX =
                              positionFromAnchor * itemTotalWidth;

                          // Calculate visibility to trigger sequential shrinking
                          final double visibleAmount =
                              displaySwipe - startX - widget.earlyShrinkOffset;

                          final double itemProgress = (visibleAmount /
                                  (itemTotalWidth - widget.earlyShrinkOffset))
                              .clamp(0.0, 1.0);

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: widget.actionSpacing / 2,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                action.onTap();
                                if (widget.closeOnActionTap) closeSlidable();
                              },
                              child: Opacity(
                                opacity: itemProgress,
                                child: Transform.scale(
                                  scale: itemProgress,
                                  child: Container(
                                    width: currentWidth,
                                    height: buttonSize,
                                    decoration: BoxDecoration(
                                      color: action.color,
                                      borderRadius: widget.actionBorderRadius,
                                    ),
                                    child: AnimatedAlign(
                                      duration: const Duration(
                                        milliseconds: 150,
                                      ),
                                      curve: Curves.easeOut,
                                      alignment: iconAlignment,
                                      child: SizedBox(
                                        width: buttonSize,
                                        height: buttonSize,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: action.child,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // The sliding foreground tile
          Transform.translate(
            offset: Offset(
              isLeftAction ? displaySwipeAmount : -displaySwipeAmount,
              0,
            ),
            child: Container(color: widget.tileColor, child: widget.child),
          ),
        ],
      ),
    );
  }
}
