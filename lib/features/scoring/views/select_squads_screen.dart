import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../../teams/models/team_model.dart';
import '../controllers/scoring_notifier.dart';
import 'scoring_screen.dart';

class SelectSquadsScreen extends ConsumerStatefulWidget {
  final TeamModel teamA;
  final TeamModel teamB;
  final String format;
  final int overs;
  final String tossWinner;
  final String tossChoice;

  const SelectSquadsScreen({
    super.key,
    required this.teamA,
    required this.teamB,
    required this.format,
    required this.overs,
    required this.tossWinner,
    required this.tossChoice,
  });

  @override
  ConsumerState<SelectSquadsScreen> createState() => _SelectSquadsScreenState();
}

class _SelectSquadsScreenState extends ConsumerState<SelectSquadsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _currentStep = 0; // 0 = Batting Team, 1 = Bowling Team, 2 = Summary

  List<TeamMember> _teamAMembers = [];
  List<TeamMember> _teamBMembers = [];

  // Squad lists of names selected as playing
  List<String> _selectedTeamAPlayers = [];
  List<String> _selectedTeamBPlayers = [];

  // Dynamic guest/custom players added in UI
  final List<String> _customTeamAPlayers = [];
  final List<String> _customTeamBPlayers = [];

  // Selected openers
  String? _striker;
  String? _nonStriker;
  String? _openingBowler;

  final _guestNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSquads();
  }

  @override
  void dispose() {
    _guestNameController.dispose();
    super.dispose();
  }

  Future<void> _loadSquads() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('team_members')
          .select()
          .inFilter('team_id', [widget.teamA.id, widget.teamB.id]);

      final List<TeamMember> loaded =
          (response as List).map((m) => TeamMember.fromMap(m)).toList();

      setState(() {
        _teamAMembers = loaded.where((m) => m.teamId == widget.teamA.id).toList();
        _teamBMembers = loaded.where((m) => m.teamId == widget.teamB.id).toList();

        // Default all registered players to playing
        _selectedTeamAPlayers = _teamAMembers.map((m) => m.userName).toList();
        _selectedTeamBPlayers = _teamBMembers.map((m) => m.userName).toList();

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load team members: $e';
        _isLoading = false;
      });
    }
  }

  bool get _isTeamABattingFirst {
    return (widget.tossWinner == 'teamA' && widget.tossChoice == 'bat') ||
        (widget.tossWinner == 'teamB' && widget.tossChoice == 'bowl');
  }

  TeamModel get _battingTeam => _isTeamABattingFirst ? widget.teamA : widget.teamB;
  TeamModel get _bowlingTeam => _isTeamABattingFirst ? widget.teamB : widget.teamA;

  List<TeamMember> get _battingTeamMembers =>
      _isTeamABattingFirst ? _teamAMembers : _teamBMembers;
  List<TeamMember> get _bowlingTeamMembers =>
      _isTeamABattingFirst ? _teamBMembers : _teamAMembers;

  List<String> get _battingSelectedPlayers =>
      _isTeamABattingFirst ? _selectedTeamAPlayers : _selectedTeamBPlayers;
  List<String> get _bowlingSelectedPlayers =>
      _isTeamABattingFirst ? _selectedTeamBPlayers : _selectedTeamAPlayers;

  List<String> get _battingCustomPlayers =>
      _isTeamABattingFirst ? _customTeamAPlayers : _customTeamBPlayers;
  List<String> get _bowlingCustomPlayers =>
      _isTeamABattingFirst ? _customTeamBPlayers : _customTeamAPlayers;

  void _addGuestPlayer(bool isBattingTeam) {
    final name = _guestNameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      if (isBattingTeam) {
        if (_isTeamABattingFirst) {
          _customTeamAPlayers.add(name);
          _selectedTeamAPlayers.add(name);
        } else {
          _customTeamBPlayers.add(name);
          _selectedTeamBPlayers.add(name);
        }
      } else {
        if (_isTeamABattingFirst) {
          _customTeamBPlayers.add(name);
          _selectedTeamBPlayers.add(name);
        } else {
          _customTeamAPlayers.add(name);
          _selectedTeamAPlayers.add(name);
        }
      }
      _guestNameController.clear();
    });
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: AppColors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildIndicatorNode(0, 'BATTING TEAM'),
          _buildIndicatorLine(),
          _buildIndicatorNode(1, 'BOWLING TEAM'),
          _buildIndicatorLine(),
          _buildIndicatorNode(2, 'SUMMARY'),
        ],
      ),
    );
  }

  Widget _buildIndicatorNode(int index, String label) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? AppColors.primaryYellow
                : isActive
                    ? AppColors.primaryYellow
                    : AppColors.black,
            border: Border.all(
              color: isActive || isDone ? AppColors.primaryYellow : AppColors.white,
              width: 1.5,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 12, color: AppColors.black)
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isActive ? AppColors.black : AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Rajdhani',
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.primaryYellow : const Color(0xFFAAAAAA),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
      ],
    );
  }

  Widget _buildIndicatorLine() {
    return Container(
      width: 16,
      height: 1.5,
      color: const Color(0xFF444444),
    );
  }

  Widget _buildSquadSelectionStep({
    required TeamModel team,
    required List<TeamMember> registeredMembers,
    required List<String> selectedList,
    required List<String> customList,
    required bool isBattingTeam,
  }) {
    final allNames = [
      ...registeredMembers.map((m) => m.userName),
      ...customList,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 4, height: 22, color: AppColors.primaryYellow),
            const SizedBox(width: 8),
            Text(
              'SELECT PLAYING SQUAD: ${team.name.toUpperCase()}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Add Guest TextField
        Container(
          decoration: BoxDecoration(
            color: AppColors.black,
            border: Border.all(color: AppColors.white, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _guestNameController,
                  style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans'),
                  decoration: const InputDecoration(
                    hintText: 'Add Guest Player Name',
                    hintStyle: TextStyle(color: Color(0xFF888888), fontSize: 13),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _addGuestPlayer(isBattingTeam),
                ),
              ),
              InkWell(
                onTap: () => _addGuestPlayer(isBattingTeam),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: AppColors.primaryYellow,
                  alignment: Alignment.center,
                  child: const Text(
                    'ADD',
                    style: TextStyle(
                      color: AppColors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'SELECT PLAYERS (MINIMUM 2 REQUIRED)',
          style: TextStyle(
            color: AppColors.primaryYellow,
            fontFamily: 'DM Sans',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.black, width: 1.5),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allNames.length,
            itemBuilder: (ctx, idx) {
              final name = allNames[idx];
              final isSelected = selectedList.contains(name);
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.black, width: 1)),
                ),
                child: CheckboxListTile(
                  title: Text(
                    name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: 'DM Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  value: isSelected,
                  activeColor: AppColors.primaryYellow,
                  checkColor: AppColors.black,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        if (!selectedList.contains(name)) selectedList.add(name);
                      } else {
                        selectedList.remove(name);
                        // Clean up opener if deselected
                        if (isBattingTeam) {
                          if (_striker == name) _striker = null;
                          if (_nonStriker == name) _nonStriker = null;
                        } else {
                          if (_openingBowler == name) _openingBowler = null;
                        }
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        if (isBattingTeam) ...[
          // Batters selection dropdowns
          const Text(
            'SELECT OPENING BATTERS',
            style: TextStyle(
              color: AppColors.primaryYellow,
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildOpenerDropdown(
            label: 'STRIKER (BATTER 1)',
            value: _striker,
            options: selectedList.where((n) => n != _nonStriker).toList(),
            onChanged: (val) => setState(() => _striker = val),
          ),
          const SizedBox(height: 12),
          _buildOpenerDropdown(
            label: 'NON-STRIKER (BATTER 2)',
            value: _nonStriker,
            options: selectedList.where((n) => n != _striker).toList(),
            onChanged: (val) => setState(() => _nonStriker = val),
          ),
        ] else ...[
          // Bowler selection dropdown
          const Text(
            'SELECT OPENING BOWLER',
            style: TextStyle(
              color: AppColors.primaryYellow,
              fontFamily: 'DM Sans',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildOpenerDropdown(
            label: 'OPENING BOWLER',
            value: _openingBowler,
            options: selectedList,
            onChanged: (val) => setState(() => _openingBowler = val),
          ),
        ],
      ],
    );
  }

  Widget _buildOpenerDropdown({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.black,
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: AppColors.black,
          iconEnabledColor: AppColors.primaryYellow,
          isExpanded: true,
          style: const TextStyle(color: AppColors.white, fontFamily: 'DM Sans', fontSize: 13),
          hint: Text(
            'Choose $label',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
          ),
          items: options.map((name) {
            return DropdownMenuItem<String>(
              value: name,
              child: Text(name.toUpperCase()),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(width: 4, height: 22, color: AppColors.primaryYellow),
            const SizedBox(width: 8),
            Text(
              'MATCH CONFIGURATION SUMMARY',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.black,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryRow('FORMAT / OVERS', '${widget.format} (${widget.overs} Overs Limit)'),
              const Divider(color: Color(0xFF333333)),
              _buildSummaryRow('HOME TEAM', widget.teamA.name),
              _buildSummaryRow('AWAY TEAM', widget.teamB.name),
              const Divider(color: Color(0xFF333333)),
              _buildSummaryRow('TOSS', '${widget.tossWinner.toUpperCase()} won & chose to ${widget.tossChoice.toUpperCase()}'),
              const Divider(color: Color(0xFF333333)),
              _buildSummaryRow('STRIKER', _striker ?? 'Not Selected', isWarning: _striker == null),
              _buildSummaryRow('NON-STRIKER', _nonStriker ?? 'Not Selected', isWarning: _nonStriker == null),
              _buildSummaryRow('OPENING BOWLER', _openingBowler ?? 'Not Selected', isWarning: _openingBowler == null),
              const Divider(color: Color(0xFF333333)),
              _buildSummaryRow('BATTING PLAYERS', '${_battingSelectedPlayers.length} selected'),
              _buildSummaryRow('BOWLING PLAYERS', '${_bowlingSelectedPlayers.length} selected'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isWarning ? AppColors.red : AppColors.primaryYellow,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  void _onNext() {
    if (_currentStep == 0) {
      // Validate Batting Team
      if (_battingSelectedPlayers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 2 playing players for the batting team.'), backgroundColor: AppColors.red),
        );
        return;
      }
      if (_striker == null || _nonStriker == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both opening batters (Striker & Non-Striker).'), backgroundColor: AppColors.red),
        );
        return;
      }
      setState(() => _currentStep = 1);
    } else if (_currentStep == 1) {
      // Validate Bowling Team
      if (_bowlingSelectedPlayers.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least 2 playing players for the bowling team.'), backgroundColor: AppColors.red),
        );
        return;
      }
      if (_openingBowler == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the opening bowler.'), backgroundColor: AppColors.red),
        );
        return;
      }
      setState(() => _currentStep = 2);
    } else if (_currentStep == 2) {
      // Final confirmation & Start scoring!
      ref.read(scoringProvider.notifier).startNewMatchWithPlayers(
            teamA: widget.teamA.name,
            teamB: widget.teamB.name,
            format: widget.format,
            overs: widget.overs,
            tossWinner: widget.tossWinner,
            tossChoice: widget.tossChoice,
            striker: _striker!,
            nonStriker: _nonStriker!,
            bowler: _openingBowler!,
            teamAPlayers: _selectedTeamAPlayers,
            teamBPlayers: _selectedTeamBPlayers,
          );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ScoringScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MATCH SQUAD SETTING',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primaryYellow,
                letterSpacing: 1.2,
              ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.red)))
              : Column(
                  children: [
                    _buildStepIndicator(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _currentStep == 0
                            ? _buildSquadSelectionStep(
                                team: _battingTeam,
                                registeredMembers: _battingTeamMembers,
                                selectedList: _battingSelectedPlayers,
                                customList: _battingCustomPlayers,
                                isBattingTeam: true,
                              )
                            : _currentStep == 1
                                ? _buildSquadSelectionStep(
                                    team: _bowlingTeam,
                                    registeredMembers: _bowlingTeamMembers,
                                    selectedList: _bowlingSelectedPlayers,
                                    customList: _bowlingCustomPlayers,
                                    isBattingTeam: false,
                                  )
                                : _buildSummaryStep(),
                      ),
                    ),
                    // Navigation strip
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: AppColors.black, width: 2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            OutlinedButton(
                              onPressed: () => setState(() => _currentStep--),
                              child: const Text('BACK'),
                            )
                          else
                            const SizedBox.shrink(),
                          ElevatedButton(
                            onPressed: _onNext,
                            child: Text(
                              _currentStep == 2 ? 'START MATCH  →' : 'NEXT STEP  →',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
