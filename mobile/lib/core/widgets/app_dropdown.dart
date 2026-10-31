import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// A non-editable anchor avoids text-field focus/keyboard changes when opening.
class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.options,
    required this.onChanged,
    this.compact = false,
  });
  final bool compact;
  final T value;
  final String label;
  final Map<T, String> options;
  final ValueChanged<T> onChanged;
  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  final controller = MenuController();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => MenuAnchor(
      controller: controller,
      crossAxisUnconstrained: false,
      style: MenuStyle(
        alignment: Alignment.bottomLeft,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 4),
        ),
        minimumSize: WidgetStatePropertyAll(Size(bounds.maxWidth, 0)),
        maximumSize: WidgetStatePropertyAll(Size(bounds.maxWidth, 220)),
        backgroundColor: const WidgetStatePropertyAll(AppColors.white),
        surfaceTintColor: const WidgetStatePropertyAll(AppColors.transparent),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      menuChildren: widget.options.entries
          .map(
            (entry) => MenuItemButton(
              style: ButtonStyle(
                textStyle: const WidgetStatePropertyAll(AppTextStyles.body),
                minimumSize: WidgetStatePropertyAll(Size(bounds.maxWidth, 48)),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                backgroundColor: WidgetStateProperty.resolveWith(
                  (states) =>
                      states.contains(WidgetState.focused) ||
                          states.contains(WidgetState.hovered)
                      ? AppColors.lightBlue
                      : AppColors.white,
                ),
              ),
              onPressed: () {
                controller.close();
                if (entry.key != widget.value) widget.onChanged(entry.key);
              },
              child: SizedBox(
                width: (bounds.maxWidth - 24).clamp(0, double.infinity),
                child: Text(
                  entry.value,
                  style: AppTextStyles.body,
                  softWrap: true,
                ),
              ),
            ),
          )
          .toList(),
      builder: (context, menu, child) => Semantics(
        button: true,
        label: widget.label,
        value: widget.options[widget.value],
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: AppColors.transparent,
          focusColor: AppColors.transparent,
          highlightColor: AppColors.transparent,
          splashColor: AppColors.transparent,
          onTap: () {
            if (menu.isOpen) {
              menu.close();
            } else {
              menu.open();
            }
          },
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              labelText: widget.label,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
            ),
            child: Row(
              children: [
                if (widget.compact) ...[
                  Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(widget.options[widget.value] ?? '', style: AppTextStyles.body))),
                  const SizedBox(width: 2),
                ] else
                  Expanded(
                    child: Text(
                      widget.options[widget.value] ?? '',
                      style: AppTextStyles.body,
                    ),
                  ),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}


