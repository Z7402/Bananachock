import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'provider_task.dart';
import 'model_task_record.dart';
import 'widget_add_task_dialog.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final taskList = ref.watch(taskProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final todayTasks = taskList.where((t) =>
        t.date.year == _selectedDate.year &&
        t.date.month == _selectedDate.month &&
        t.date.day == _selectedDate.day).toList();

    final Map<String, Duration> categoryDurations = {};
    for (var task in todayTasks) {
      categoryDurations[task.category] = (categoryDurations[task.category] ?? Duration.zero) + task.duration;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddTaskDialog(context, ref),
            tooltip: '记录任务',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DateSelector(selectedDate: _selectedDate, onDateChanged: (d) => setState(() => _selectedDate = d)),
            const SizedBox(height: 20),
            Text('今日分类占比', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: categoryDurations.isEmpty
                  ? Center(child: Text('暂无数据，请先记录任务', style: TextStyle(color: colorScheme.onSurfaceVariant)))
                  : _CategoryPieChart(categoryDurations: categoryDurations),
            ),
            const SizedBox(height: 24),
            Text('本周每日时长趋势', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(height: 260, child: _WeeklyTrendChart(taskList: taskList)),
            const SizedBox(height: 20),
            Text('今日任务记录', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (todayTasks.isEmpty)
              Padding(padding: const EdgeInsets.only(top: 16), child: Center(child: Text('今天还没有记录任务', style: TextStyle(color: colorScheme.onSurfaceVariant))))
            else
              ...todayTasks.map((task) => _TaskCard(task: task, onDelete: () => ref.read(taskProvider.notifier).deleteTask(task.id))),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        onAdd: (title, category, duration) {
          final task = TaskRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title, category: category, date: _selectedDate, duration: duration,
          );
          ref.read(taskProvider.notifier).addTask(task);
        },
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  const _DateSelector({required this.selectedDate, required this.onDateChanged});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(icon: const Icon(Icons.chevron_left_rounded), onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1)))),
        Text(dateFormat.format(selectedDate), style: Theme.of(context).textTheme.titleMedium),
        IconButton(icon: const Icon(Icons.chevron_right_rounded), onPressed: () => onDateChanged(selectedDate.add(const Duration(days: 1)))),
      ],
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, Duration> categoryDurations;
  const _CategoryPieChart({required this.categoryDurations});

  static const categoryColors = {
    '学习': Color(0xFF4CAF50), '娱乐': Color(0xFFFF9800), '运动': Color(0xFF2196F3),
    '工作': Color(0xFF9C27B0), '阅读': Color(0xFF795548), '其他': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final totalSeconds = categoryDurations.values.fold(0, (sum, d) => sum + d.inSeconds);
    final entries = categoryDurations.entries.toList();
    return Row(children: [
      Expanded(flex: 3, child: PieChart(PieChartData(
        sections: entries.map((entry) {
          final percentage = (entry.value.inSeconds / totalSeconds * 100).toStringAsFixed(0);
          final color = categoryColors[entry.key] ?? Colors.grey;
          return PieChartSectionData(color: color, value: entry.value.inSeconds.toDouble(), title: '$percentage%', radius: 60,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
        }).toList(), centerSpaceRadius: 30,
      ))),
      const SizedBox(width: 8),
      Expanded(flex: 2, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
        children: entries.map((entry) {
          final color = categoryColors[entry.key] ?? Colors.grey;
          return Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Row(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: Text(entry.key, style: Theme.of(context).textTheme.bodySmall, overflow: TextOverflow.ellipsis)),
          ]));
        }).toList(),
      )),
    ]);
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<TaskRecord> taskList;
  const _WeeklyTrendChart({required this.taskList});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final dailyHours = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      return taskList.where((t) => t.date.year == date.year && t.date.month == date.month && t.date.day == date.day)
          .fold(0.0, (sum, t) => sum + t.duration.inMinutes / 60.0);
    });
    final maxY = dailyHours.isEmpty ? 8.0 : (dailyHours.reduce((a, b) => a > b ? a : b) * 1.3).clamp(2.0, 16.0);

    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (v) => FlLine(color: cs.outlineVariant.withOpacity(0.3), strokeWidth: 1)),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30,
          getTitlesWidget: (v, m) => Text('${v.toInt()}h', style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)))),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
          getTitlesWidget: (v, m) {
            const days = ['一','二','三','四','五','六','日'];
            return Padding(padding: const EdgeInsets.only(top: 8), child: Text(days[v.toInt()], style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)));
          })),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false), minX: 0, maxX: 6, minY: 0, maxY: maxY,
      lineBarsData: [LineChartBarData(
        spots: dailyHours.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
        isCurved: true, curveSmoothness: 0.3, color: cs.primary, barWidth: 3, isStrokeCapRound: true,
        dotData: FlDotData(show: true, getDotPainter: (s, x, b, i) => FlDotCirclePainter(radius: 4, color: cs.primary, strokeWidth: 2, strokeColor: cs.surface)),
        belowBarData: BarAreaData(show: true, gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [cs.primary.withOpacity(0.2), cs.primary.withOpacity(0.02)])),
      )],
    ));
  }
}

class _TaskCard extends StatelessWidget {
  final TaskRecord task;
  final VoidCallback onDelete;
  const _TaskCard({required this.task, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hours = task.duration.inHours;
    final minutes = task.duration.inMinutes % 60;
    final durationStr = hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';
    return Card(elevation: 0, color: cs.surfaceContainerLow, margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(task.title), subtitle: Text(task.category),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(durationStr, style: TextStyle(color: cs.primary)), const SizedBox(width: 8),
          IconButton(icon: Icon(Icons.delete_outline, color: cs.error, size: 20), onPressed: onDelete),
        ]),
      ),
    );
  }
}