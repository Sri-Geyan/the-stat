import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme.dart';
import '../../../core/storage/hive_registry.dart';

const _teamEmojis = ['🏏', '🦁', '🐯', '🦅', '⚡', '👑', '🔥', '🐺', '⚔️', '🛡️', '🦈', '🦖'];
const _tournamentEmojis = ['🏆', '🏅', '🎖️', '👑', '🏏', '🌟', '💥', '🔥', '🎯', '🚩'];

String getCleanName(String name) {
  final emojis = [..._teamEmojis, ..._tournamentEmojis];
  for (final emoji in emojis) {
    if (name.startsWith('$emoji ')) {
      return name.substring(emoji.length + 1);
    }
    if (name.startsWith(emoji)) {
      return name.substring(emoji.length);
    }
  }
  return name;
}

Widget _buildTournamentLogo(String name, {double size = 44, double fontSize = 18}) {
  final cleanName = getCleanName(name);
  final box = Hive.box(HiveRegistry.tournamentLogosBoxName);
  final logoBase64 = box.get(cleanName) as String?;

  if (logoBase64 != null && logoBase64.isNotEmpty) {
    try {
      final bytes = base64Decode(logoBase64);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryYellow, width: 1.5),
          color: AppColors.black,
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildLetterFallback(cleanName, size, fontSize),
        ),
      );
    } catch (_) {
      return _buildLetterFallback(cleanName, size, fontSize);
    }
  }
  return _buildLetterFallback(cleanName, size, fontSize);
}

Widget _buildLetterFallback(String cleanName, double size, double fontSize) {
  final letter = cleanName.trim().isNotEmpty ? cleanName.trim()[0].toUpperCase() : '?';
  return Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.black,
      border: Border.all(color: AppColors.white, width: 1.5),
    ),
    child: Text(
      letter,
      style: TextStyle(
        color: AppColors.primaryYellow,
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
        fontFamily: 'Rajdhani',
      ),
    ),
  );
}

class TournamentsScreen extends StatefulWidget {
  const TournamentsScreen({super.key});

  @override
  State<TournamentsScreen> createState() => _TournamentsScreenState();
}

class _TournamentsScreenState extends State<TournamentsScreen> {
  // Mock tournament data (in-memory for now)
  final List<_Tournament> _tournaments = [
    _Tournament(
      name: 'Chennai Corporate Cup 2024',
      format: 'T10',
      teams: ['TCS Warriors', 'Infosys Eagles', 'Wipro Tigers', 'Accenture Lions'],
      status: 'Ongoing',
      startDate: '01 Jun 2024',
    ),
    _Tournament(
      name: 'Gully Premier League S3',
      format: 'Gully T5',
      teams: ['Street Kings', 'Colony Boys', 'Park Enders', 'Railway FC', 'School Ground XI', 'Temple Street CC'],
      status: 'Upcoming',
      startDate: '15 Jun 2024',
    ),
    _Tournament(
      name: 'Box Cricket Blast 2024',
      format: 'Box Cricket T6',
      teams: ['Blue Smashers', 'Red Rockets', 'Green Giants', 'Golden Hawks'],
      status: 'Completed',
      startDate: '20 May 2024',
    ),
  ];

  void _showCreateTournamentDialog() {
    final nameCtrl = TextEditingController();
    String format = 'T20';
    String? selectedLogoBase64;
 
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.primaryGreen,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.primaryYellow, width: 2),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setModal) {
          final name = nameCtrl.text.trim();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 20, right: 20, top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(width: 4, height: 28, color: AppColors.primaryYellow),
                    const SizedBox(width: 10),
                    Text('CREATE TOURNAMENT', style: Theme.of(context).textTheme.headlineMedium),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('TOURNAMENT NAME', style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
                  ),
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
                    onChanged: (val) => setModal(() {}),
                    decoration: const InputDecoration(
                      hintText: 'e.g. Chennai Premier League',
                      hintStyle: TextStyle(color: Color(0xFF888888), fontFamily: 'DM Sans', fontSize: 13),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('LOGO PREVIEW', style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryYellow, width: 2),
                        color: AppColors.black,
                      ),
                      child: selectedLogoBase64 != null
                          ? Image.memory(
                              base64Decode(selectedLogoBase64!),
                              fit: BoxFit.cover,
                            )
                          : Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryYellow,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Rajdhani',
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryYellow,
                            foregroundColor: AppColors.black,
                          ),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 400,
                              maxHeight: 400,
                            );
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setModal(() {
                                selectedLogoBase64 = base64Encode(bytes);
                              });
                            }
                          },
                          child: const Text('PICK IMAGE  📸'),
                        ),
                        if (selectedLogoBase64 != null) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              setModal(() {
                                selectedLogoBase64 = null;
                              });
                            },
                            child: const Text(
                              'REMOVE IMAGE',
                              style: TextStyle(color: AppColors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('FORMAT', style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    color: AppColors.black,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 1.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: format,
                      dropdownColor: AppColors.black,
                      iconEnabledColor: AppColors.primaryYellow,
                      isExpanded: true,
                      style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
                      items: ['Gully T5', 'Gully T8', 'Box Cricket T6', 'Corporate T10', 'T20', 'ODI'].map((f) {
                        return DropdownMenuItem(value: f, child: Text(f));
                      }).toList(),
                      onChanged: (val) => setModal(() => format = val ?? format),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isNotEmpty) {
                      final rawName = nameCtrl.text.trim();
                      if (selectedLogoBase64 != null) {
                        final box = Hive.box(HiveRegistry.tournamentLogosBoxName);
                        await box.put(rawName, selectedLogoBase64);
                      }
                      setState(() {
                        _tournaments.insert(0, _Tournament(
                          name: rawName,
                          format: format,
                          teams: [],
                          status: 'Upcoming',
                          startDate: 'TBD',
                        ));
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('CREATE TOURNAMENT'),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _confirmDeleteTournament(int index) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.black,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: BorderSide(color: AppColors.primaryYellow, width: 2),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning, color: AppColors.red),
              const SizedBox(width: 10),
              Text(
                'DELETE TOURNAMENT',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.red),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to delete the tournament "${_tournaments[index].name}"? This will permanently delete it.',
            style: const TextStyle(
              color: AppColors.white,
              fontFamily: 'DM Sans',
            ),
          ),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.white, width: 1.5),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.black, width: 1.5),
              ),
              onPressed: () {
                setState(() {
                  _tournaments.removeAt(index);
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tournament deleted successfully.'),
                    backgroundColor: AppColors.primaryGreen,
                  ),
                );
              },
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TOURNAMENTS', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: AppColors.primaryYellow)),
      ),
      body: _tournaments.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primaryYellow, size: 64),
                  const SizedBox(height: 16),
                  Text('NO TOURNAMENTS YET', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text('Tap + to create your first tournament.', style: TextStyle(color: AppColors.white, fontFamily: 'DM Sans')),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tournaments.length,
              itemBuilder: (ctx, i) => _buildTournamentCard(_tournaments[i], i),
            ),
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          heroTag: 'tournaments_fab',
          shape: const CircleBorder(side: BorderSide(color: AppColors.primaryYellow, width: 2.5)),
          backgroundColor: AppColors.black,
          onPressed: _showCreateTournamentDialog,
          child: const Icon(Icons.add, color: AppColors.primaryYellow, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTournamentCard(_Tournament t, int index) {
    Color statusColor;
    switch (t.status) {
      case 'Ongoing': statusColor = AppColors.red; break;
      case 'Upcoming': statusColor = const Color(0xFF0088FF); break;
      default: statusColor = const Color(0xFF666666);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryGreen,
          border: Border.all(color: statusColor, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: AppColors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(t.format.toUpperCase(), style: const TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _confirmDeleteTournament(index),
                        child: const Icon(Icons.delete, color: AppColors.red, size: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    color: statusColor,
                    child: Text(t.status.toUpperCase(), style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildTournamentLogo(t.name),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          getCleanName(t.name).toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.primaryYellow, size: 14),
                      const SizedBox(width: 6),
                      Text('Starts: ${t.startDate}', style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 13)),
                      const Spacer(),
                      const Icon(Icons.groups, color: AppColors.primaryYellow, size: 14),
                      const SizedBox(width: 6),
                      Text('${t.teams.length} Teams', style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 13)),
                    ],
                  ),
                  if (t.teams.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: t.teams.map((team) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primaryYellow, width: 1),
                        ),
                        child: Text(team, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 11)),
                      )).toList(),
                    ),
                  ],
                  if (t.status == 'Ongoing') ...[
                    const SizedBox(height: 12),
                    _buildPointsTable(t),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPointsTable(_Tournament t) {
    // Mock points table data
    final mockStandings = t.teams.asMap().entries.map((e) {
      final pts = (t.teams.length - e.key) * 4 - (e.key * 2);
      final m = t.teams.length - 1;
      final w = t.teams.length - 1 - e.key;
      final l = e.key;
      return {'team': e.value, 'm': m, 'w': w, 'l': l, 'pts': pts > 0 ? pts : 0};
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('POINTS TABLE', style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(border: Border.all(color: AppColors.black, width: 1)),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: AppColors.black,
                child: const Row(
                  children: [
                    Expanded(child: Text('TEAM', style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.bold))),
                    SizedBox(width: 28, child: Text('M', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.bold))),
                    SizedBox(width: 28, child: Text('W', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.bold))),
                    SizedBox(width: 28, child: Text('L', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.bold))),
                    SizedBox(width: 36, child: Text('PTS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.primaryYellow, fontFamily: 'DM Sans', fontSize: 10, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              ...mockStandings.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  color: i % 2 == 0 ? AppColors.primaryGreen : const Color(0xFF155200),
                  child: Row(
                    children: [
                      Expanded(child: Text(s['team'] as String, style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 12), overflow: TextOverflow.ellipsis)),
                      SizedBox(width: 28, child: Text('${s['m']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontFamily: 'Rajdhani', fontSize: 13))),
                      SizedBox(width: 28, child: Text('${s['w']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontFamily: 'Rajdhani', fontSize: 13))),
                      SizedBox(width: 28, child: Text('${s['l']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontFamily: 'Rajdhani', fontSize: 13))),
                      SizedBox(width: 36, child: Text('${s['pts']}', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primaryYellow, fontFamily: 'Rajdhani', fontSize: 15, fontWeight: FontWeight.bold))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tournament {
  final String name;
  final String format;
  final List<String> teams;
  final String status;
  final String startDate;
  _Tournament({required this.name, required this.format, required this.teams, required this.status, required this.startDate});
}
