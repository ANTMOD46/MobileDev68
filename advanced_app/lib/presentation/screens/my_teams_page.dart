// File: my_teams_page.dart
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
// import 'package:get/get.dart'; // ลบออก เนื่องจากไม่ได้ใช้งานฟีเจอร์ของ GetX
// import 'main.dart'; // ลบออก เนื่องจากไม่ได้อ้างอิงถึงโค้ดใน main.dart

class MyTeamsPage extends StatefulWidget {
  const MyTeamsPage({Key? key}) : super(key: key);

  @override
  State<MyTeamsPage> createState() => _MyTeamsPageState();
}

class _MyTeamsPageState extends State<MyTeamsPage> {
  late final GetStorage _box;
  late List<Map<String, dynamic>> _createdTeams;

  @override
  void initState() {
    super.initState();
    _box = GetStorage();
    _loadTeams();
  }

  void _loadTeams() {
    final teams = _box.read<List>('createdTeams');
    if (teams != null) {
      _createdTeams = teams.cast<Map<String, dynamic>>();
    } else {
      _createdTeams = [];
    }
  }

  void _saveTeams() {
    _box.write('createdTeams', _createdTeams);
  }

  void _showEditTeamDialog(int teamIndex) {
    // โค้ดส่วนนี้ลอกมาจาก _TeamBuilderState เพื่อให้แก้ไขทีมได้
    final originalTeam = _createdTeams[teamIndex];
    String newTeamName = originalTeam['teamName'] as String;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('แก้ไขทีม "${originalTeam['teamName']}"'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ชื่อทีม:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: TextEditingController(text: newTeamName),
                  onChanged: (value) => newTeamName = value.trim(),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'ตั้งชื่อทีมใหม่',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text('สมาชิกทีม (${(originalTeam['members'] as List).length}/3):', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...((originalTeam['members'] as List).cast<Map<String, dynamic>>()).map((member) {
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(member['imageUrl'] as String),
                    ),
                    title: Text(member['name'] as String),
                    subtitle: Text('ID: ${member['id']}'),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _createdTeams[teamIndex]['teamName'] = newTeamName;
                });
                _saveTeams();
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(
                    content: Text('แก้ไขชื่อทีมเป็น "$newTeamName" เรียบร้อยแล้ว!'),
                    backgroundColor: Colors.green,
                  ));
              },
              child: const Text('บันทึก'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _createdTeams.removeAt(teamIndex);
                });
                _saveTeams();
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(
                    content: Text('ลบทีมเรียบร้อยแล้ว!'),
                    backgroundColor: Colors.red,
                  ));
              },
              child: const Text('ลบทีม', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ทีมของฉัน'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
      body: _createdTeams.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีทีมที่สร้างไว้',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _createdTeams.length,
              itemBuilder: (context, index) {
                final team = _createdTeams[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _TeamCard(
                    team: team,
                    onTap: () => _showEditTeamDialog(index),
                  ),
                );
              },
            ),
    );
  }
}

// Class สำหรับแสดงการ์ดทีม
class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield, size: 24, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      team['teamName'] as String,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: (team['members'] as List).cast<Map<String, dynamic>>().map((member) {
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: NetworkImage(member['imageUrl'] as String),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member['name'] as String,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}