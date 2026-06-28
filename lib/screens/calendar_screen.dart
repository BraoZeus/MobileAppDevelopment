import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late Map<DateTime, List<Map<String, dynamic>>> _calendarEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _calendarEvents = {};
    _fetchEventsFromFirebase();
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Color-coder helper based on the event type
  Color _getEventColor(String type) {
    switch (type) {
      case 'assignment':
        return Colors.redAccent;
      case 'test':
        return Colors.purple;
      case 'study_plan':
        return const Color(0xFF334195); // Your app's theme color
      default:
        return Colors.grey;
    }
  }

  void _fetchEventsFromFirebase() {
    // Listens to a unified 'calendar_events' collection handling assignments, tests, and study plans
    FirebaseFirestore.instance.collection('calendar_events').snapshots().listen((snapshot) {
      final Map<DateTime, List<Map<String, dynamic>>> newEvents = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] == null) continue;

        final Timestamp timestamp = data['date'];
        final DateTime eventDate = timestamp.toDate();
        final DateTime normalizedDate = _normalizeDate(eventDate);

        final eventItem = {
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'description': data['description'] ?? '',
          'type': data['type'] ?? 'assignment',
          'date': eventDate,
        };

        if (newEvents[normalizedDate] == null) {
          newEvents[normalizedDate] = [];
        }
        newEvents[normalizedDate]!.add(eventItem);
      }

      setState(() {
        _calendarEvents = newEvents;
        _selectedEvents = _calendarEvents[_normalizeDate(_selectedDay!)] ?? [];
      });
    });
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _calendarEvents[_normalizeDate(day)] ?? [];
  }

  // Opens a quick bottom panel to log a task/test/plan directly into Firebase
  void _showAddEventBottomSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = 'assignment';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Calendar Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    const Text('Event Type:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: selectedType,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'assignment', child: Text('Assignment (Red)')),
                        DropdownMenuItem(value: 'test', child: Text('Test Date (Purple)')),
                        DropdownMenuItem(value: 'study_plan', child: Text('Study Plan (Indigo)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334195),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () async {
                        if (titleController.text.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('calendar_events').add({
                            'title': titleController.text,
                            'description': descController.text,
                            'type': selectedType,
                            'date': Timestamp.fromDate(_selectedDay!),
                          });
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('Save Event', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study & Academic Calendar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF334195),
        centerTitle: true,
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2025, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                _selectedEvents = _getEventsForDay(selectedDay);
              });
            },
            // Customizing calendar markers to display multiple colors on the matrix cells
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.take(4).map((event) {
                    final item = event as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.0),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getEventColor(item['type']),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(color: const Color(0xFF334195).withValues(alpha: 0.3), shape: BoxShape.circle),
              selectedDecoration: const BoxDecoration(color: Color(0xFF334195), shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          ),
          const Divider(),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('Clear day! No upcoming due dates or study tracks.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                Color categoryColor = _getEventColor(event['type']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                      ),
                    ),
                    title: Text(event['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${event['type'].toString().replaceAll('_', ' ').toUpperCase()}\n${event['description']}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF334195),
        onPressed: _showAddEventBottomSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}