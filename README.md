# Improve nested `SafeArea` widgets with `baseMinimum`

This proposal introduces an improvement to Flutter's core `SafeArea` widget by adding a `baseMinimum` property to solve unwanted padding accumulation in nested layouts.

## The Problem

Currently, `SafeArea` uses the `minimum` property to specify the minimum padding applied. The `SafeArea` widget then ensures that the greater of the `minimum` insets and the physical media padding (like the status bar or notch) is applied.

However, when `SafeArea` widgets are composed and nested within each other, their `minimum` values are **additive**.

Imagine you have an outer layout that wants to ensure its content doesn't hit the absolute edges of the screen, so it wraps its content in a `SafeArea` with a minimum padding:

```dart
SafeArea(
  minimum: EdgeInsets.all(10), // Ensures at least 10px from edges
  child: SomeLayout(
    child: SafeArea(
      minimum: EdgeInsets.only(bottom: 30), // A nested component requesting exactly 30px
      child: BottomButton(),
    ),
  ),
)
```

In the current implementation, the bottom padding applied to the innermost child will be **`40px`** (`10` from the outer + `30` from the inner). 

If you nest more `SafeArea`s, these minimum values will keep accumulating, pushing your UI further away than intended. The nested component merely wanted *at least* 30 pixels of clearance from the physical edge—not 40 or 50. This breaks composability since a generic UI component cannot know if it is already wrapped in a `SafeArea`, forcing developers to strip `SafeArea`s out of nested views or write complex `MediaQuery` math manually.

## The Proposed Solution: `baseMinimum`

This PR introduces the **`baseMinimum`** property to natively solve this layout composition problem.

Instead of blindly accumulating padding like `minimum`, `baseMinimum` evaluates the padding *already applied* by ancestor `SafeArea` widgets using an internal inherited widget (`_SafeAreaPadding`).

If an ancestor has already applied 20px of padding, and a child requests a `baseMinimum` of 30px, the child will only apply the remaining 10px to satisfy the total minimum required distance. If the ancestor applied 40px, the child will apply 0px. This ensures your components always get exactly the minimum clearance they evaluate they need.

## Usage

The `baseMinimum` API works exactly like `minimum`, but is intended for composed widgets that want to define their own spacing requirements from the physical edges, without accumulating unnecessary padding from parent wrappers:

```dart
class NestedWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // The child will have exactly 30px spacing from the bottom, or the 
      // system padding/ancestor padding, whichever is GREATER in total!
      baseMinimum: const EdgeInsets.only(bottom: 30),
      child: const Text('Hello World'),
    );
  }
}
```

This ensures that Flutter UI components constructed with `SafeArea` can remain modular, cleanly composable, and responsive to any arbitrary parent wrapper tree.
