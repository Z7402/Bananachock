import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'provider_task.dart';
import 'model_task_record.dart';
import 'widget_add_task_dialog.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskList = ref.watch(taskProvider);
    final todayTasks = taskList
        .where(
          (t) =>
              t.date.year == _selectedDate.year &&
              t.date.month == _selectedDate.month &&
              t.date.day == _selectedDate.day,
        )
        .toList();

    final Map<String, Duration> categoryMap = {};
    for (var t in todayTasks) {
      categoryMap[t.category] =
          (categoryMap[t.category] ?? Duration.zero) + t.duration;
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('统计'),
            centerTitle: true,
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _showAddTaskDialog(context, ref),
                tooltip: '记录任务',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: '日'),
                Tab(text: '周'),
                Tab(text: '月'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _DailyView(
              date: _selectedDate,
              todayTasks: todayTasks,
              categoryMap: categoryMap,
              taskList: taskList,
              onDateChanged: (d) => setState(() => _selectedDate = d),
              onDeleteTask: (id) {
                final task = taskList.where((t) => t.id == id).firstOrNull;
                if (task != null) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('删除任务'),
                      content: Text('确定删除「${task.title}」？'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('取消'),
                        ),
                        FilledButton(
                          onPressed: () {
                            ref.read(taskProvider.notifier).deleteTask(id);
                            Navigator.pop(ctx);
                          },
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            _WeeklyView(taskList: taskList),
            _MonthlyView(taskList: taskList),
          ],
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        onAdd: (title, description, category, duration) {
          final task = TaskRecord(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            title: title,
            description: description,
            category: category,
            date: _selectedDate,
            duration: duration,
          );
          ref.read(taskProvider.notifier).addTask(task);
        },
      ),
    );
  }
}

class _DailyView extends ConsumerWidget {
  final DateTime date;
  final List<TaskRecord> todayTasks;
  final Map<String, Duration> categoryMap;
  final List<TaskRecord> taskList;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String>? onDeleteTask;
  const _DailyView({
    required this.date,
    required this.todayTasks,
    required this.categoryMap,
    required this.taskList,
    required this.onDateChanged,
    this.onDeleteTask,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final totalMinutes = todayTasks.fold(
      0,
      (sum, t) => sum + t.duration.inMinutes,
    );
    final taskDurationSummary = <String, Duration>{};
    for (final task in todayTasks) {
      taskDurationSummary[task.title] =
          (taskDurationSummary[task.title] ?? Duration.zero) + task.duration;
    }
    final taskDurationEntries = taskDurationSummary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateSelector(selectedDate: date, onDateChanged: onDateChanged),
          const SizedBox(height: 16),
          // 日总计卡片
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.primaryContainer,
                  cs.primaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '今日专注',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(totalMinutes / 60).toStringAsFixed(1)} h',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '共 ${todayTasks.length} 个任务',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onPrimaryContainer.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 分类饼图
          if (categoryMap.isNotEmpty) ...[
            Text('分类占比', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: _CategoryPieChart(categoryDurations: categoryMap),
            ),
            const SizedBox(height: 20),
          ],
          // 同名任务时长汇总
          Text('任务时长汇总', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (taskDurationEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '暂无汇总数据',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              clipBehavior: Clip.antiAlias,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: cs.outlineVariant),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                    ),
                    children: const [
                      _SummaryCell('任务名', isHeader: true),
                      _SummaryCell('累计时长', isHeader: true, alignEnd: true),
                    ],
                  ),
                  ...taskDurationEntries.map(
                    (entry) => TableRow(
                      children: [
                        _SummaryCell(entry.key),
                        _SummaryCell(
                          _formatDuration(entry.value),
                          alignEnd: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          // 任务列表
          Text('任务记录', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (todayTasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '暂无记录',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...todayTasks.map(
              (task) => _TaskCard(
                task: task,
                onEdit: () => _showEditTaskDialog(context, task),
                onDelete: () => onDeleteTask?.call(task.id),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showEditTaskDialog(
    BuildContext context,
    TaskRecord task,
  ) async {
    final titleController = TextEditingController(text: task.title);
    final descriptionController = TextEditingController(text: task.description);
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('编辑任务'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '任务名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: '主要内容（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isEmpty) return;
              Navigator.pop(dialogContext, (
                title,
                descriptionController.text.trim(),
              ));
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    if (result == null || !context.mounted) return;
    ref
        .read(taskProvider.notifier)
        .updateTask(task.copyWith(title: result.$1, description: result.$2));
  }
}

class _WeeklyView extends StatelessWidget {
  final List<TaskRecord> taskList;
  const _WeeklyView({required this.taskList});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final dailyHours = List.generate(7, (i) {
      final date = weekStart.add(Duration(days: i));
      return taskList
          .where(
            (t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day,
          )
          .fold(0.0, (sum, t) => sum + t.duration.inMinutes / 60.0);
    });
    final maxY = dailyHours.isEmpty
        ? 8.0
        : (dailyHours.reduce((a, b) => a > b ? a : b) * 1.3).clamp(2.0, 16.0);
    final totalWeek = dailyHours.fold(0.0, (a, b) => a + b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.secondaryContainer,
                  cs.secondaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '本周总计',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSecondaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${totalWeek.toStringAsFixed(1)} h',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: cs.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('每日趋势', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: _WeeklyChart(dailyHours: dailyHours, maxY: maxY),
          ),
          const SizedBox(height: 16),
          // 每日详情
          ...List.generate(7, (i) {
            final date = weekStart.add(Duration(days: i));
            final hours = dailyHours[i];
            final tasks = taskList
                .where(
                  (t) =>
                      t.date.year == date.year &&
                      t.date.month == date.month &&
                      t.date.day == date.day,
                )
                .toList();
            final weekDays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
            final dayLabel =
                '${date.month}/${date.day} ${weekDays[date.weekday - 1]}';
            return Card(
              color: cs.surfaceContainerLow,
              margin: const EdgeInsets.only(bottom: 6),
              child: ExpansionTile(
                title: Text('$dayLabel  ${hours.toStringAsFixed(1)}h'),
                children: tasks
                    .map(
                      (t) => ListTile(
                        title: Text(t.title),
                        subtitle: Text(t.category),
                        trailing: Text('${t.duration.inMinutes}min'),
                      ),
                    )
                    .toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MonthlyView extends StatelessWidget {
  final List<TaskRecord> taskList;
  const _MonthlyView({required this.taskList});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyHours = List.generate(daysInMonth, (i) {
      final date = DateTime(now.year, now.month, i + 1);
      return taskList
          .where(
            (t) =>
                t.date.year == date.year &&
                t.date.month == date.month &&
                t.date.day == date.day,
          )
          .fold(0.0, (sum, t) => sum + t.duration.inMinutes / 60.0);
    });
    final totalMonth = dailyHours.fold(0.0, (a, b) => a + b);
    final maxY = dailyHours.isEmpty
        ? 8.0
        : (dailyHours.reduce((a, b) => a > b ? a : b) * 1.3).clamp(2.0, 16.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cs.tertiaryContainer,
                  cs.tertiaryContainer.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${now.month}月总计',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onTertiaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  '${totalMonth.toStringAsFixed(1)} h',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('每日热度', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SizedBox(
            height: 260,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barGroups: dailyHours
                    .asMap()
                    .entries
                    .map(
                      (e) => BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value,
                            color: e.value > 0
                                ? cs.primary
                                : cs.outlineVariant.withValues(alpha: 0.3),
                            width: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    )
                    .toList(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (v, m) => Text(
                        '${v.toInt()}h',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, m) {
                        if (v.toInt() % 5 == 1)
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${v.toInt() + 1}',
                              style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          );
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  static const _cnWeekday = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  @override
  Widget build(BuildContext context) {
    final label =
        '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日 ${_cnWeekday[selectedDate.weekday]}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () =>
              onDateChanged(selectedDate.subtract(const Duration(days: 1))),
        ),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: () =>
              onDateChanged(selectedDate.add(const Duration(days: 1))),
        ),
      ],
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, Duration> categoryDurations;
  const _CategoryPieChart({required this.categoryDurations});

  static const categoryColors = {
    '学习': Color(0xFF4CAF50),
    '娱乐': Color(0xFFFF9800),
    '运动': Color(0xFF2196F3),
    '工作': Color(0xFF9C27B0),
    '阅读': Color(0xFF795548),
    '其他': Color(0xFF607D8B),
  };

  @override
  Widget build(BuildContext context) {
    final totalSeconds = categoryDurations.values.fold(
      0,
      (sum, d) => sum + d.inSeconds,
    );
    final entries = categoryDurations.entries.toList();
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: entries.map((entry) {
                final pct = (entry.value.inSeconds / totalSeconds * 100)
                    .toStringAsFixed(0);
                return PieChartSectionData(
                  color: categoryColors[entry.key] ?? Colors.grey,
                  value: entry.value.inSeconds.toDouble(),
                  title: '$pct%',
                  radius: 55,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
              centerSpaceRadius: 25,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: categoryColors[entry.key],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${entry.key} ${(entry.value.inMinutes / 60).toStringAsFixed(1)}h',
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<double> dailyHours;
  final double maxY;
  const _WeeklyChart({required this.dailyHours, required this.maxY});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (v, m) => Text(
                '${v.toInt()}h',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                const days = ['一', '二', '三', '四', '五', '六', '日'];
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    days[v.toInt()],
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: dailyHours
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            curveSmoothness: 0.35,
            color: cs.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (s, x, b, i) => FlDotCirclePainter(
                radius: 4,
                color: cs.primary,
                strokeWidth: 2,
                strokeColor: cs.surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  cs.primary.withValues(alpha: 0.2),
                  cs.primary.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}min';
  if (minutes > 0) return '${minutes}min ${seconds}s';
  return '${seconds}s';
}

class _SummaryCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool alignEnd;
  const _SummaryCell(this.text, {this.isHeader = false, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskRecord task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  const _TaskCard({required this.task, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hours = task.duration.inHours;
    final minutes = task.duration.inMinutes % 60;
    final durationStr = hours > 0 ? '${hours}h ${minutes}min' : '$minutes min';
    return Card(
      elevation: 0,
      color: cs.surfaceContainerLow,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text('任务：${task.title}'),
        subtitle: Text(
          task.description.isEmpty
              ? task.category
              : '主要内容：${task.description}\n${task.category}',
        ),
        isThreeLine: task.description.isNotEmpty,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              durationStr,
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 18, color: cs.primary),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
              tooltip: '编辑',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: cs.error.withValues(alpha: 0.7),
              ),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }
}
