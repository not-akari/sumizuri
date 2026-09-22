import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/theming/app_layout.dart';

class FeedRow extends StatelessWidget {
  const FeedRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final Widget leading;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: context.layout.gutter,
        vertical: 4,
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      onTap: onTap,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if (subtitle != null)
                  DefaultTextStyle(
                    style: TextStyle(fontSize: 12.5, color: cs.outline),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: subtitle!,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}
