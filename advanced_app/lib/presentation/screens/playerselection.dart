import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'my_teams_page.dart';
import 'package:get/get.dart'; 
// Class สำหรับ Error และ Retry
class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'พบข้อผิดพลาด: $message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}

// Class สำหรับแสดงประเภท Pokemon
class _TypeBadge extends StatelessWidget {
  final String text;
  const _TypeBadge({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Class สำหรับข้อมูล Pokemon
class _Pokemon {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;

  const _Pokemon({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
  });
}

class TeamBuilder extends StatefulWidget {
  const TeamBuilder({super.key});

  @override
  State<TeamBuilder> createState() => _TeamBuilderState();
}

class _TeamBuilderState extends State<TeamBuilder> {
  static const int teamSize = 3;

  // Team info
  final TextEditingController _teamNameCtrl = TextEditingController();
  String _teamName = '';

  // Data from API
  List<_Pokemon> _all = [];
  bool _loading = false;
  String? _error;

  // All available types from fetched list
  List<String> _allTypes = [];
  final Set<String> _selectedTypes = {};

  // Selection: keep IDs for robustness
  final Set<int> _selectedIds = {};

  // Search
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Store multiple teams
  late final GetStorage _box;
  late List<Map<String, dynamic>> _createdTeams;

  @override
  void initState() {
    super.initState();
    _box = GetStorage();
    _loadTeams();
    _teamNameCtrl.text = 'ทีมใหม่';
    _teamName = 'ทีมใหม่';
    _fetchPokemons();
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

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchPokemons() async {
    setState(() {
      _loading = true;
      _error = null;
      _all = [];
      _allTypes = [];
      _selectedTypes.clear();
    });
    try {
      final res = await http.get(
        Uri.parse('https://pokeapi.co/api/v2/pokemon?limit=150'),
      );
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final results = (json['results'] as List).cast<Map<String, dynamic>>();

      final detailFutures = results.map((e) async {
        final name = (e['name'] as String).trim();
        final url = (e['url'] as String).trim();
        final id = _idFromPokeUrl(url);

        final dres = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'));
        if (dres.statusCode != 200) {
          throw Exception('Detail HTTP ${dres.statusCode}');
        }
        final dj = jsonDecode(dres.body) as Map<String, dynamic>;
        final types = ((dj['types'] as List?) ?? [])
            .map((t) => (t as Map<String, dynamic>)['type']['name'] as String)
            .map((s) => s.toString().toLowerCase())
            .toList();

        return _Pokemon(
          id: id,
          name: _capitalize(name),
          imageUrl: _officialArtwork(id),
          types: types,
        );
      }).toList();

      final list = await Future.wait(detailFutures);

      final typeSet = <String>{};
      for (final p in list) {
        typeSet.addAll(p.types);
      }
      final allTypes = typeSet.map(_capitalize).toList()..sort();

      setState(() {
        _all = list;
        _allTypes = allTypes;
      });

      if (mounted) {
        for (final p in list) {
          precacheImage(NetworkImage(p.imageUrl), context);
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int _idFromPokeUrl(String url) {
    final segs = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty).toList();
    return int.tryParse(segs.last) ?? 0;
  }

  String _officialArtwork(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/other/official-artwork/$id.png';

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  void _toggleSelect(_Pokemon p) {
    final selected = _selectedIds.contains(p.id);
    setState(() {
      if (selected) {
        _selectedIds.remove(p.id);
      } else {
        if (_selectedIds.length >= teamSize) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text('ทีมสามารถมีสมาชิกได้สูงสุด $teamSize คนเท่านั้น'),
              backgroundColor: Colors.orange,
            ));
          return;
        }
        _selectedIds.add(p.id);
      }
    });
  }

  void _toggleType(String displayType) {
    final t = displayType.toLowerCase();
    setState(() {
      if (_selectedTypes.contains(t)) {
        _selectedTypes.remove(t);
      } else {
        _selectedTypes.add(t);
      }
    });
  }

  void _createTeam() {
    if (_teamName.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('กรุณาตั้งชื่อทีม'),
          backgroundColor: Colors.red,
        ));
      return;
    }

    if (_selectedIds.length < teamSize) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text('กรุณาเลือกสมาชิกทีมให้ครบ $teamSize คน'),
          backgroundColor: Colors.red,
        ));
      return;
    }

    final selectedMembers = _all.where((p) => _selectedIds.contains(p.id)).toList();
    final teamData = {
      'teamName': _teamName.trim(),
      'members': selectedMembers.map((p) => {
            'id': p.id,
            'name': p.name,
            'imageUrl': p.imageUrl,
            'types': p.types,
          }).toList(),
    };

    setState(() {
      _createdTeams.add(teamData);
      _selectedIds.clear();
      _teamName = 'ทีมใหม่';
      _teamNameCtrl.text = 'ทีมใหม่';
    });

    _saveTeams();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('สร้างทีม "${teamData['teamName']}" เรียบร้อยแล้ว!'),
        backgroundColor: Colors.green,
      ));
  }

  void _showEditTeamDialog(int teamIndex) {
    final originalTeam = _createdTeams[teamIndex];
    String newTeamName = originalTeam['teamName'] as String;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                    Text('สมาชิกทีม (${(originalTeam['members'] as List).length}/$teamSize):', style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final theme = Theme.of(context);

    // Filtered members
    final query = _query.toLowerCase().trim();
    final filtered = _all.where((p) {
      final matchName = query.isEmpty || p.name.toLowerCase().contains(query);
      final matchType = _selectedTypes.isEmpty ||
          p.types.any((t) => _selectedTypes.contains(t));
      return matchName && matchType;
    }).toList();

    return Scaffold(
  appBar: AppBar(
    title: const Text('สร้างทีม'),
    centerTitle: true,
    backgroundColor: theme.colorScheme.primaryContainer,
    foregroundColor: theme.colorScheme.onPrimaryContainer,
    actions: [
      // เพิ่มปุ่มนี้เพื่อนำทางไปหน้า MyTeamsPage
      IconButton(
        onPressed: () {
          Get.to(() => const MyTeamsPage());
        },
        icon: const Icon(Icons.shield),
        tooltip: 'ดูทีมของฉัน',
      ),
      TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('เสร็จสิ้น'),
      ),
    ],
  ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _fetchPokemons)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_createdTeams.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'ทีมที่สร้างแล้ว',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _createdTeams.length,
                            itemBuilder: (context, index) {
                              final team = _createdTeams[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  left: index == 0 ? 16 : 8,
                                  right: index == _createdTeams.length - 1 ? 16 : 8,
                                ),
                                child: IntrinsicWidth(
                                  child: _TeamCard(
                                    team: team,
                                    onTap: () => _showEditTeamDialog(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      // Team Name Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.group, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'ชื่อทีมปัจจุบัน',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _teamNameCtrl,
                              onChanged: (value) => setState(() => _teamName = value.trim()),
                              decoration: InputDecoration(
                                labelText: 'ชื่อทีม',
                                border: const OutlineInputBorder(),
                                hintText: 'ตั้งชื่อทีมของคุณ',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                suffixIcon: _teamNameCtrl.text.isNotEmpty
                                    ? IconButton(
                                        onPressed: () {
                                          _teamNameCtrl.clear();
                                          setState(() => _teamName = '');
                                        },
                                        icon: const Icon(Icons.clear),
                                        splashRadius: 20,
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Selected Members Section
                      Container(
                        height: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.people, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'สมาชิกทีม (${_selectedIds.length}/$teamSize)',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const Spacer(),
                                if (_selectedIds.isNotEmpty)
                                  TextButton(
                                    onPressed: () => setState(_selectedIds.clear),
                                    child: const Text('ล้างทั้งหมด'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _selectedIds.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'ยังไม่ได้เลือกสมาชิกทีม',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    )
                                  : ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _selectedIds.length,
                                      itemBuilder: (context, index) {
                                        final memberId = _selectedIds.toList()[index];
                                        final member = _all.firstWhere((p) => p.id == memberId);
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8),
                                          child: Chip(
                                            avatar: CircleAvatar(
                                              foregroundImage: NetworkImage(member.imageUrl),
                                              child: Text('${member.id}'),
                                            ),
                                            label: Text(member.name),
                                            deleteIcon: const Icon(Icons.close),
                                            onDeleted: () => setState(() =>
                                                _selectedIds.remove(member.id)),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: InputDecoration(
                            hintText: 'ค้นหาสมาชิก…',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _query.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _query = '');
                                    },
                                    icon: const Icon(Icons.clear),
                                    splashRadius: 20,
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      // Type filter chips
                      if (_allTypes.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Text('กรองตามประเภท:'),
                              const Spacer(),
                              if (_selectedTypes.isNotEmpty)
                                TextButton(
                                  onPressed: () => setState(_selectedTypes.clear),
                                  child: const Text('ล้างการกรอง'),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _allTypes.map((tDisplay) {
                                final active = _selectedTypes.contains(tDisplay.toLowerCase());
                                return FilterChip(
                                  selected: active,
                                  label: Text(tDisplay),
                                  onSelected: (_) => _toggleType(tDisplay),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (_query.isNotEmpty || _selectedTypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ผลการค้นหา: ${filtered.length} คน',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      const Divider(),
                      // Members Grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3 / 4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final selected = _selectedIds.contains(p.id);
                          final reachedLimit = !selected && _selectedIds.length >= teamSize;

                          return AnimatedOpacity(
                            duration: const Duration(milliseconds: 180),
                            opacity: reachedLimit ? 0.6 : 1.0,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _toggleSelect(p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: selected ? theme.colorScheme.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.25),
                                            blurRadius: 16,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 6),
                                          )
                                        ]
                                      : const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: Offset(0, 3),
                                          )
                                        ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      // Image
                                      Positioned.fill(
                                        child: Image.network(
                                          p.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stack) {
                                            return Container(
                                              color: Colors.grey.shade300,
                                              alignment: Alignment.center,
                                              child: const Icon(Icons.image_not_supported, size: 40),
                                            );
                                          },
                                        ),
                                      ),
                                      // Gradient + name + types
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [Colors.transparent, Colors.black54],
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                p.name,
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Wrap(
                                                alignment: WrapAlignment.center,
                                                spacing: 6,
                                                children: p.types
                                                    .map((t) => _TypeBadge(text: _capitalize(t)))
                                                    .toList(),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Check badge
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 180),
                                          opacity: selected ? 1 : 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                              boxShadow: const [
                                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
                                              ],
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(Icons.check, size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      // Create Team Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton.icon(
              onPressed: _selectedIds.length == teamSize && _teamName.trim().isNotEmpty ? _createTeam : null,
              icon: const Icon(Icons.group_add),
              label: Text(
                _selectedIds.length == teamSize
                    ? 'สร้างทีม "$_teamName"'
                    : 'เลือกสมาชิกให้ครบ $teamSize คน (${_selectedIds.length}/$teamSize)',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _selectedIds.length == teamSize
                    ? theme.colorScheme.primary
                    : Colors.grey,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// New component for Team Card
class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final VoidCallback onTap;

  const _TeamCard({
    required this.team,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final members = (team['members'] as List).cast<Map<String, dynamic>>();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140, // กำหนดความกว้างเพื่อไม่ให้มันขยายไปทั้งหน้าจอ
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade100, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              team['teamName'] as String,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'สมาชิก ${members.length} คน',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: members.map((member) {
                return CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(member['imageUrl'] as String),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}