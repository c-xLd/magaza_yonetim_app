import 'package:flutter/material.dart';

class UpcomingTasksSheet extends StatelessWidget {
  final List<Map<String, String>> tasks;

  const UpcomingTasksSheet({Key? key, required this.tasks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text('Yaklaşan Görevler', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 18),
          ...tasks.take(3).map((task) => Card(
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorScheme.primary.withOpacity(0.13),
                child: Icon(Icons.calendar_today, color: colorScheme.primary),
              ),
              title: Text(task['desc'] ?? '', style: textTheme.bodyLarge),
              subtitle: Text(task['date'] ?? '', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
            ),
          )),
          if (tasks.length > 3)
            Center(
              child: TextButton(
                onPressed: () {},
                child: const Text('Tümünü Gör'),
              ),
            ),
        ],
      ),
    );
  }
}
