import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/project_provider.dart';
import '../models/project_model.dart';
import '../widgets/project_form_dialog.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  // Helper to parse the hex color string back into a Flutter Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  // Opens the creation dialog
  Future<void> _showCreateDialog(ProjectProvider provider) async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => const ProjectFormDialog(),
    );
    if (result != null && mounted) {
      provider.addProject(result);
    }
  }

// Opens the edit dialog pre-filled with existing project data
  Future<void> _showEditDialog(
      Project project, ProjectProvider provider) async {
    final result = await showDialog<Project>(
      context: context,
      builder: (context) => ProjectFormDialog(project: project),
    );
    if (result != null && mounted) {
      provider.updateProject(result);
    }
  }

// Shows a confirmation prompt before deleting
  Future<void> _showDeleteDialog(
      Project project, ProjectProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Project?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${project.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      provider.deleteProject(project.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the project provider for real-time updates
    final projectProvider = context.watch<ProjectProvider>();
    final activeProjects = projectProvider.projects;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton(
      backgroundColor: const Color(0xFF334195),
      onPressed: () => _showCreateDialog(projectProvider),
      child: const Icon(Icons.add, color: Colors.white),
      ),
      body: projectProvider.isLoadingDB
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF334195)))
          : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildScheduleOverview(),
            const SizedBox(height: 32),
            _buildActiveProjectsHeader(activeProjects.length),
            const SizedBox(height: 16),
            if (activeProjects.isEmpty)
              const Center(child: Text("No active projects. Click + to add one!", style: TextStyle(color: Colors.grey))),
            ...activeProjects.map((project) => _buildProjectCard(project, projectProvider)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FA),
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircleAvatar(backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11')),
      ),
      title: const Text(
        'StudySync',
        style: TextStyle(color: Color(0xFF334195), fontWeight: FontWeight.w800, fontSize: 20),
      ),
      centerTitle: true,
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF2D3142)), onPressed: () {}),
      ],
    );
  }

  // header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Project Timeline', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF2D3142))),
        SizedBox(height: 4),
        Text('Your upcoming deadlines and active workloads.', style: TextStyle(fontSize: 14, color: Colors.black54)),
      ],
    );
  }

  // schedule
  Widget _buildScheduleOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Schedule Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const SizedBox(width: 100),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nov 10', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    Text('Nov 15', style: TextStyle(fontSize: 12, color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                    Text('Nov 20', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 350,
              height: 100,
              child: Stack(
                children: [
                  Positioned(left: 175, top: 0, bottom: 0, child: Container(width: 1, color: Colors.red.shade200)),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildGanttRow('Physics Lab', const Color(0xFF334195), 'Data Collection', 80, 100),
                      _buildGanttRow('Literature Essay', Colors.teal, 'Drafting phase', 160, 80),
                      _buildGanttRow('CS Final', Colors.transparent, '', 0, 0),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
  Widget _buildGanttRow(String label, Color color, String phase, double leftOffset, double width) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        if (width > 0)
          Container(
            margin: EdgeInsets.only(left: leftOffset),
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(phase, style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis),
          )
      ],
    );
  }

  Widget _buildActiveProjectsHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Active Projects', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        Text('$count in Progress', style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildProjectCard(Project project, ProjectProvider provider) {
    Color activeColor = _hexToColor(project.tagColorHex);
    String formattedDate = DateFormat('MMM dd').format(project.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: activeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(project.tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: activeColor, letterSpacing: 1)),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Due $formattedDate', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'edit') _showEditDialog(project, provider);
                        if (value == 'delete') _showDeleteDialog(project, provider);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(children: [
                            Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2D3142)),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(project.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Progress', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
                    Text('${(project.progress * 100).toInt()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: activeColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  children: [
                    Container(height: 6, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
                    LayoutBuilder(
                      builder: (context, constraints) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 6,
                        width: constraints.maxWidth * project.progress,
                        decoration: BoxDecoration(color: activeColor, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.checklist, size: 18, color: Color(0xFF2D3142)),
                    SizedBox(width: 8),
                    Text('Subtasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                  ],
                ),
                const SizedBox(height: 4),
                ...project.subtasks.map((task) => _buildSubtaskRow(project, task, activeColor, provider)),
              ],
            ),
          ),
          if (project.alert1Day || project.alertMorning || project.alertMilestone) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            _buildAlertsSection(project, provider),
          ]
        ],
      ),
    );
  }

  Widget _buildSubtaskRow(Project project, Subtask task, Color activeColor, ProjectProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        // This triggers the provider state update, recalculates progress, and saves to Firebase!
        onTap: () => provider.toggleSubtask(project, task),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: task.isCompleted ? activeColor : Colors.transparent,
                border: Border.all(color: task.isCompleted ? activeColor : Colors.grey.shade400, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: task.isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                color: task.isCompleted ? Colors.grey : const Color(0xFF2D3142),
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(Project project, ProjectProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.notifications_active_outlined, size: 18, color: Color(0xFF2D3142)),
              SizedBox(width: 8),
              Text('Deadline Alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            ],
          ),
          const SizedBox(height: 16),
          _buildAlertToggle('1 Day Before', 'Push notification', project.alert1Day, (val) => provider.updateProjectAlerts(project, oneDay: val)),
          _buildAlertToggle('Morning of Deadline', 'Email & Push', project.alertMorning, (val) => provider.updateProjectAlerts(project, morning: val)),
          _buildAlertToggle('Milestone Alerts', 'When subtasks are due', project.alertMilestone, (val) => provider.updateProjectAlerts(project, milestone: val)),
        ],
      ),
    );
  }

  Widget _buildAlertToggle(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF334195),
            activeTrackColor: const Color(0xFF334195).withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}
