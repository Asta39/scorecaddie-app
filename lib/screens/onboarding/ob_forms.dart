import 'package:flutter/material.dart';
import 'ob_style.dart';

/// Dark form pieces shared by the in-app flows (round setup, tee times, …).

/// A bottom sheet body: dark, rounded top, grab handle, safe bottom padding.
class ObSheet extends StatelessWidget {
  const ObSheet({super.key, required this.child, this.title, this.subtitle, this.height, this.padding = const EdgeInsets.fromLTRB(22, 0, 22, 0)});
  final Widget child;
  final String? title;
  final String? subtitle;
  final double? height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        height: height,
        padding: EdgeInsets.only(bottom: mq.padding.bottom + 16),
        decoration: const BoxDecoration(color: Ob.bg, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: DefaultTextStyle(
          style: Ob.textBase,
          child: Column(mainAxisSize: height == null ? MainAxisSize.min : MainAxisSize.max, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 10),
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Ob.creamA(.2), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title!, style: Ob.display(26, height: 1.05)),
                  if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle!, style: Ob.body(13, color: Ob.creamA(.6)))],
                ]),
              ),
            if (height == null) Padding(padding: padding, child: child) else Expanded(child: Padding(padding: padding, child: child)),
          ]),
        ),
      ),
    );
  }
}

/// Opens [ObSheet] content as a modal bottom sheet.
Future<T?> showObSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );

/// Filled dark input decoration with an accent focus ring.
InputDecoration obInput(String? label, {String? hint, Color accent = Ob.lime, Widget? prefix, Widget? suffix}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefix,
      suffixIcon: suffix,
      labelStyle: Ob.body(13, color: Ob.creamA(.6)),
      floatingLabelStyle: Ob.body(13, weight: FontWeight.w700, color: accent),
      hintStyle: Ob.body(14, color: Ob.creamA(.3)),
      errorStyle: Ob.body(12, color: Ob.warn),
      filled: true,
      fillColor: Ob.cardFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: const BorderSide(color: Ob.warn)),
    );

/// A tappable option card: lime-edged when picked.
class ObSelectTile extends StatelessWidget {
  const ObSelectTile({super.key, required this.selected, required this.onTap, required this.child, this.accent = Ob.lime, this.padding = const EdgeInsets.all(14), this.width});
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  final Color accent;
  final EdgeInsets padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: width,
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: .14) : Ob.cardFill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? accent : Colors.transparent, width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Dark date/time picker theme.
Widget obPickerTheme(BuildContext context, Widget? child, {Color accent = Ob.lime}) => Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(primary: accent, onPrimary: Ob.ink, surface: Ob.cardFill, onSurface: Ob.cream),
        dialogTheme: const DialogThemeData(backgroundColor: Ob.cardFill),
      ),
      child: child!,
    );

/// A back button + title row for pushed screens.
class ObTopBar extends StatelessWidget {
  const ObTopBar(this.title, {super.key, this.onBack, this.actions = const [], this.eyebrow});
  final String title;
  final String? eyebrow;
  final VoidCallback? onBack;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ObIconButton(icon: Icons.chevron_left_rounded, label: 'Back', onPressed: onBack ?? () => Navigator.of(context).maybePop()),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (eyebrow != null) Text(eyebrow!.toUpperCase(), style: Ob.eyebrow()),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ob.display(24)),
        ]),
      ),
      for (final a in actions) ...[const SizedBox(width: 8), a],
    ]);
  }
}
