import 'package:flutter/material.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.dayNumber,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.actualCount,
    required this.hasPredicted,
    required this.onTap,
  });

  final int dayNumber;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final int actualCount;
  final bool hasPredicted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasDot = !isSelected && (actualCount > 0 || hasPredicted);
    final textColor = isSelected
        ? cs.onPrimary
        : isFuture
        ? cs.onSurface.withValues(alpha: 0.45)
        : cs.onSurface;

    return Center(
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? cs.primary : Colors.transparent,
            border: isToday && !isSelected
                ? Border.all(color: cs.primary, width: 1.2)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$dayNumber',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (hasDot)
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: actualCount > 0 ? cs.primary : Colors.transparent,
                    border: actualCount == 0
                        ? Border.all(color: cs.primary, width: 1)
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
