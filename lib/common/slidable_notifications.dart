import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Modern slidable bildirim öğesi
class SlidableNotification extends StatefulWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isRead;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsRead;

  const SlidableNotification({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.isRead,
    required this.onTap,
    required this.onDelete,
    required this.onMarkAsRead,
  });

  @override
  State<SlidableNotification> createState() => _SlidableNotificationState();
}

class _SlidableNotificationState extends State<SlidableNotification> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Slidable(
        key: ValueKey(widget.title),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Sil',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        startActionPane: !widget.isRead
            ? ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.3,
                children: [
                  SlidableAction(
                    onPressed: (_) => widget.onMarkAsRead(),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.check_circle_outline,
                    label: 'Okundu',
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                ],
              )
            : null,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
              border: Border.all(color: widget.iconColor.withOpacity(0.3), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // İkon
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: widget.iconColor, size: 22),
                    ),
                    // Başlık ve ok simgesi
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (!widget.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: widget.iconColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                                    fontWeight: widget.isRead ? FontWeight.w500 : FontWeight.bold,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _expanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.expand_more, size: 22, color: Theme.of(context).colorScheme.outline),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 0.0, top: 2.0, bottom: 2.0),
                            child: Text(
                              widget.time,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: widget.iconColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                AnimatedCrossFade(
                  firstChild: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: widget.isRead 
                          ? Theme.of(context).textTheme.titleMedium!.color 
                          : Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  secondChild: Text(
                    widget.message,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: widget.isRead 
                          ? Theme.of(context).textTheme.titleMedium!.color 
                          : Theme.of(context).textTheme.bodyLarge!.color,
                    ),
                  ),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bildirimleri gruplandırmak için başlık bileşeni
class NotificationGroupHeader extends StatelessWidget {
  final String title;
  final int count;

  const NotificationGroupHeader({
    super.key,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
