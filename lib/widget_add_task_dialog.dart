import 'package:flutter/material.dart';

class AddTaskDialog extends StatefulWidget {
  final void Function(String title, String category, Duration duration) onAdd;
  const AddTaskDialog({super.key, required this.onAdd});
  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  String _selectedCategory = '学习';
  int _hours = 0;
  int _minutes = 0;
  static const List<String> categories = ['学习', '娱乐', '运动', '工作', '阅读', '其他'];

  @override
  void dispose() { _titleController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('记录任务'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: '任务名称', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
 value: _selectedCategory,
 decoration: const InputDecoration(labelText: '分类', border: OutlineInputBorder()),
 items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
 onChanged: (v) => setState(() => _selectedCategory = v!),
 ),
          const SizedBox(height: 16),
          Text('耗时', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              Text('小时', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(width: 80, child: NumberPicker(value: _hours, min: 0, max: 23, onChanged: (v) => setState(() => _hours = v))),
            ]),
            const SizedBox(width: 16),
            Column(children: [
              Text('分钟', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(width: 80, child: NumberPicker(value: _minutes, min: 0, max: 59, onChanged: (v) => setState(() => _minutes = v))),
            ]),
          ]),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        FilledButton(onPressed: () {
          if (_titleController.text.trim().isEmpty) return;
          widget.onAdd(_titleController.text.trim(), _selectedCategory, Duration(hours: _hours, minutes: _minutes));
          Navigator.pop(context);
        }, child: const Text('保存')),
      ],
    );
  }
}

class NumberPicker extends StatelessWidget {
  final int value, min, max;
  final ValueChanged<int> onChanged;
  const NumberPicker({super.key, required this.value, required this.min, required this.max, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: value > min ? () => onChanged(value - 1) : null, visualDensity: VisualDensity.compact),
      SizedBox(width: 32, child: Text(value.toString().padLeft(2, '0'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: value < max ? () => onChanged(value + 1) : null, visualDensity: VisualDensity.compact),
    ]);
  }
}
