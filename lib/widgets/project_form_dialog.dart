import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/project_model.dart';

class ProjectFormDialog extends StatefulWidget {
  final Project? project; // null = create mode, not null = edit mode

  const ProjectFormDialog({super.key, this.project});

  @override
  State<ProjectFormDialog> createState() => _ProjectFormDialogState();
}

class _ProjectFormDialogState extends State<ProjectFormDialog> {
  final List<Subtask> _subtasks = [];
  final List<TextEditingController> _subtaskControllers = [];
  final TextEditingController _newSubtaskController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedTag = 'RESEARCH';
  DateTime? _dueDate;
  bool _alertsEnabled = false;
  bool _alert1Day = false;
  bool _alertMorning = false;
  bool _alertMilestone = false;

  bool get _isEditMode => widget.project != null;

  // Maps tag name to its hex color — add new types here later
  static const _tagColors = {
    'RESEARCH': '#334195',
    'WRITING': '#009688',
  };

  static Color _parseHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final p = widget.project!;
      _titleController.text = p.title;
      _selectedTag = p.tag;
      _dueDate = p.dueDate;
      _alert1Day = p.alert1Day;
      _alertMorning = p.alertMorning;
      _alertMilestone = p.alertMilestone;
      // Master toggle is on if any alert is active
      _alertsEnabled = p.alert1Day || p.alertMorning || p.alertMilestone;
      for (final s in p.subtasks) {
        final clone = Subtask(id: s.id, title: s.title, isCompleted: s.isCompleted);
        _subtasks.add(clone);
        _subtaskControllers.add(TextEditingController(text: clone.title));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _subtaskControllers) {
      c.dispose();
    }
    _newSubtaskController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF334195),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title.')),
      );
      return;
    }
    if (_dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a due date.')),
      );
      return;
    }

    // Build the result Project — preserve id and subtasks on edit
    final result = Project(
      id: widget.project?.id,
      title: title,
      tag: _selectedTag,
      tagColorHex: _tagColors[_selectedTag]!,
      dueDate: _dueDate!,
      subtasks: _subtasks,
      alert1Day: _alertsEnabled && _alert1Day,
      alertMorning: _alertsEnabled && _alertMorning,
      alertMilestone: _alertsEnabled && _alertMilestone,
    );

    Navigator.pop(context, result);
  }

  void _addSubtask() {
    final text = _newSubtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(Subtask(title: text));
      _subtaskControllers.add(TextEditingController(text: text));
      _newSubtaskController.clear();
    });
  }

  void _removeSubtask(int index) {
    setState(() {
      _subtaskControllers[index].dispose();
      _subtaskControllers.removeAt(index);
      _subtasks.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        _isEditMode ? 'Edit Project' : 'New Project',
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Title ──────────────────────────────────────────────
            _label('Project Title'),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDeco('e.g. Physics Lab Report'),
            ),
            const SizedBox(height: 20),

            // ── Tag / Type ─────────────────────────────────────────
            _label('Project Type'),
            const SizedBox(height: 8),
            Row(
              children: _tagColors.keys.map((tag) {
                final isSelected = _selectedTag == tag;
                final color = _parseHex(_tagColors[tag]!);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: tag == 'RESEARCH' ? 8.0 : 0.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedTag = tag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color:
                          isSelected ? color : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade200),
                        ),
                        child: Text(
                          tag,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Due Date ───────────────────────────────────────────
            _label('Due Date'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF334195)),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate == null
                          ? 'Select due date'
                          : DateFormat('MMM dd, yyyy').format(_dueDate!),
                      style: TextStyle(
                        color: _dueDate == null
                            ? Colors.grey.shade400
                            : const Color(0xFF2D3142),
                        fontWeight: _dueDate == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Subtasks ───────────────────────────────────────────
            _label('Subtasks'),
            const SizedBox(height: 8),
            ...List.generate(_subtasks.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskControllers[index],
                        onChanged: (val) => _subtasks[index].title = val,
                        decoration: _inputDeco('Subtask title'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeSubtask(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newSubtaskController,
                    decoration: _inputDeco('Add a subtask...'),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF334195)),
                  onPressed: _addSubtask,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Deadline Alerts ────────────────────────────────────
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Master toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(children: [
                        Icon(Icons.notifications_outlined,
                            size: 18, color: Color(0xFF334195)),
                        SizedBox(width: 8),
                        Text('Deadline Alerts',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142))),
                      ]),
                      Switch(
                        value: _alertsEnabled,
                        activeThumbColor: const Color(0xFF334195),
                        onChanged: (val) => setState(() {
                          _alertsEnabled = val;
                          // Turning master off clears all sub-toggles
                          if (!val) {
                            _alert1Day = false;
                            _alertMorning = false;
                            _alertMilestone = false;
                          }
                        }),
                      ),
                    ],
                  ),
                  // Sub-toggles — only visible when master is on
                  if (_alertsEnabled) ...[
                    Divider(color: Colors.grey.shade200, height: 1),
                    _alertRow(
                      '1 Day Before',
                      'Push notification',
                      _alert1Day,
                          (v) => setState(() => _alert1Day = v),
                    ),
                    _alertRow(
                      'Morning of Deadline',
                      'Push notification at 8 AM',
                      _alertMorning,
                          (v) => setState(() => _alertMorning = v),
                    ),
                    _alertRow(
                      'Milestone Alerts',
                      'When a subtask is completed',
                      _alertMilestone,
                          (v) => setState(() => _alertMilestone = v),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF334195),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _submit,
          child: Text(_isEditMode ? 'Save Changes' : 'Create Project'),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black54,
          fontSize: 13));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.grey.shade50,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: Color(0xFF334195), width: 1.5)),
  );

  Widget _alertRow(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142))),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Switch(
              value: value,
              activeThumbColor: const Color(0xFF334195),
              onChanged: onChanged),
        ],
      ),
    );
  }
}