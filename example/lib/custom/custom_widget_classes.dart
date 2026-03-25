import 'package:flutter/material.dart';

/// CustomText — switch on fontType for TextStyle.
class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    this.fontType = 'body',
    this.color = 0xFF000000,
    this.maxLines,
  });

  final String text;
  final String fontType;
  final int color;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    final style = switch (fontType) {
      'heading' =>
        TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c),
      'button' =>
        TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c),
      'caption' => TextStyle(fontSize: 12, color: c),
      _ => TextStyle(fontSize: 14, color: c),
    };
    return Text(text, style: style, maxLines: maxLines);
  }
}

/// CustomBounceTapper — GestureDetector wrapper.
class CustomBounceTapper extends StatelessWidget {
  const CustomBounceTapper({
    super.key,
    this.onTap,
    this.child,
  });

  final VoidCallback? onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}

/// NullConditionalWidget — null coalescing children.
class NullConditionalWidget extends StatelessWidget {
  const NullConditionalWidget({
    super.key,
    this.child,
    this.nullChild,
  });

  final Widget? child;
  final Widget? nullChild;

  @override
  Widget build(BuildContext context) {
    return child ?? nullChild ?? const SizedBox.shrink();
  }
}

/// CustomButton — ElevatedButton wrapper.
class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      onLongPress: onLongPress,
      child: child,
    );
  }
}

/// CustomBadge — Container with formatted text.
class CustomBadge extends StatelessWidget {
  const CustomBadge({
    super.key,
    this.label = '',
    this.count = 0,
    this.backgroundColor = 0xFF9E9E9E,
  });

  final String label;
  final int count;
  final int backgroundColor;

  @override
  Widget build(BuildContext context) {
    final bg = Color(backgroundColor);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        '$label${count > 0 ? ' ($count)' : ''}',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

/// CustomProgressBar — ClipRRect + LinearProgressIndicator.
class CustomProgressBar extends StatelessWidget {
  const CustomProgressBar({
    super.key,
    this.value = 0.0,
    this.color = 0xFF2196F3,
    this.shape = 'rounded',
    this.height = 4.0,
  });

  final double value;
  final int color;
  final String shape;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(shape == 'rounded' ? height / 2 : 0),
      child: LinearProgressIndicator(
        value: value,
        color: Color(color),
        minHeight: height,
      ),
    );
  }
}

/// CustomColumn — spacing + divider between children.
class CustomColumn extends StatelessWidget {
  const CustomColumn({
    super.key,
    this.spacing = 0.0,
    this.dividerColor = 0x00000000,
    this.children = const [],
  });

  final double spacing;
  final int dividerColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dc = Color(dividerColor);
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        if (spacing > 0) items.add(SizedBox(height: spacing));
        if (dc.a > 0) {
          items.add(Divider(color: dc, height: 1));
        }
      }
      items.add(children[i]);
    }
    return Column(children: items);
  }
}

/// SkeletonContainer — loading state conditional.
class SkeletonContainer extends StatelessWidget {
  const SkeletonContainer({
    super.key,
    this.isLoading = false,
    this.child,
  });

  final bool isLoading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        height: 48,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return child ?? const SizedBox.shrink();
  }
}

/// CompareWidget — Column with conditional children.
class CompareWidget extends StatelessWidget {
  const CompareWidget({
    super.key,
    this.child,
    this.trueChild,
    this.falseChild,
  });

  final Widget? child;
  final Widget? trueChild;
  final Widget? falseChild;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (child != null) child!,
      if (trueChild != null) trueChild!,
      if (falseChild != null) falseChild!,
    ]);
  }
}

/// PvContainer — postFrameCallback + child.
class PvContainer extends StatelessWidget {
  const PvContainer({
    super.key,
    this.onPv,
    this.child,
  });

  final VoidCallback? onPv;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onPv?.call());
    return child ?? const SizedBox.shrink();
  }
}

/// CustomCard — GestureDetector + Card.
class CustomCard extends StatelessWidget {
  const CustomCard({
    super.key,
    required this.child,
    this.elevation = 1.0,
    this.borderRadius = 8.0,
    this.onTap,
  });

  final Widget child;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: child,
      ),
    );
  }
}

/// CustomTile — ListTile wrapper.
class CustomTile extends StatelessWidget {
  const CustomTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// CustomAppBar — AppBar wrapper.
class CustomAppBar extends StatelessWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.actions = const [],
  });

  final Widget? title;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: title,
      actions: actions.isEmpty ? null : actions,
      backgroundColor: const Color(0xFF2196F3),
    );
  }
}
