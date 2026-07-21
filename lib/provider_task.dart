import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'model_task_record.dart';

class TaskNotifier extends StateNotifier<List<TaskRecord>> {
  TaskNotifier() : super([]) {
    _loadFromStorage();
  }

  static const _storageKey = 'bananachock_tasks';

  void addTask(TaskRecord record) {
    state = [...state, record];
    _saveToStorage();
  }

  void deleteTask(String id) {
    state = state.where((t) => t.id != id).toList();
    _saveToStorage();
  }

  List<TaskRecord> getTasksForDate(DateTime date) {
    return state.where((t) =>
        t.date.year == date.year &&
        t.date.month == date.month &&
        t.date.day == date.day).toList();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        state = jsonList.map((e) => TaskRecord.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        // 数据损坏时清空旧记录，下次保存会覆盖
        state = [];
      }
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(state.map((t) => t.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}

final taskProvider = StateNotifierProvider<TaskNotifier, List<TaskRecord>>((ref) {
  return TaskNotifier();
});