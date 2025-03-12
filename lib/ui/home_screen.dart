import 'package:flutter/material.dart';
import 'package:schedule_generator/services/gemini_service.dart';
import 'schedule_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> tasks = [];
  final TextEditingController taskController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  String? priority;
  bool isLoading = false;

  void _addTask() {
    if (taskController.text.isNotEmpty &&
        durationController.text.isNotEmpty &&
        priority != null) {
      setState(() {
        tasks.add({
          "name": taskController.text,
          "priority": priority!,
          "duration": int.tryParse(durationController.text) ?? 30,
          "deadline": "Tidak Ada",
        });
      });
      taskController.clear();
      durationController.clear();
    }
  }

  void _clearTasks() {
    setState(() => tasks.clear());
  }

  Future<void> _generateSchedule() async {
    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠ Harap tambahkan tugas terlebih dahulu!")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String schedule = await GeminiService.generateSchedule(tasks);
      await Future.delayed(Duration(seconds: 1));

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScheduleResultScreen(scheduleResult: schedule),
        ),
      ).then((_) {
        setState(() => isLoading = false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menghasilkan jadwal: $e")),
      );
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule Generator"),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: InputDecoration(
                labelText: "Nama Tugas",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: "Durasi (menit)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: priority,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Pilih Prioritas",
              ),
              onChanged: (value) => setState(() => priority = value),
              items: ["Tinggi", "Sedang", "Rendah"]
                  .map((priorityMember) => DropdownMenuItem(
                        value: priorityMember,
                        child: Text(priorityMember),
                      ))
                  .toList(),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _addTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Tambahkan Tugas"),
                ),
                ElevatedButton(
                  onPressed: _clearTasks,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Hapus Semua"),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 6),
                    color: Colors.orange[100],
                    child: ListTile(
                      title: Text(
                        "${task['name']}",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Prioritas: ${task['priority']} | Durasi: ${task['duration']} menit",
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 10),
            isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _generateSchedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Generate Schedule"),
                  ),
          ],
        ),
      ),
    );
  }
}
