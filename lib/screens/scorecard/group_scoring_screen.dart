import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_card.dart';
import '../../providers/app_providers.dart';
import '../../core/database/database.dart';
import '../../core/cloud/group_sync_service.dart';

class GroupScoringScreen extends ConsumerStatefulWidget {
  final int courseId;
  final String groupRoundId;
  final String mode; // INDIVIDUAL_DEVICES or SINGLE_DEVICE

  const GroupScoringScreen({
    super.key,
    required this.courseId,
    required this.groupRoundId,
    required this.mode,
  });

  @override
  ConsumerState<GroupScoringScreen> createState() => _GroupScoringScreenState();
}

class _GroupScoringScreenState extends ConsumerState<GroupScoringScreen> {
  late PageController _pageController;
  int _currentHoleIndex = 0;
  
  Course? _course;
  List<int> _holePars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    final db = ref.read(databaseProvider);
    final course = await db.getCourse(widget.courseId);
    
    List<int> pars = [];
    try {
      final List<dynamic> parsed = jsonDecode(course.holePars);
      pars = parsed.map((e) => e as int).toList();
    } catch (_) {
      pars = List.filled(18, 4);
    }

    setState(() {
      _course = course;
      _holePars = pars;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final groupSync = ref.read(groupSyncServiceProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return StreamBuilder<DocumentSnapshot>(
      stream: groupSync.watchGroupRound(widget.groupRoundId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final scores = (data['scores'] as Map<String, dynamic>? ?? {});
        final participants = List.from(data['participants'] as List);
        
        return Scaffold(
          backgroundColor: const Color(0xFFF6F5F0),
          appBar: _buildAppBar(data, scores, user?.uid),
          body: Column(
            children: [
              _buildHoleProgress(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentHoleIndex = idx),
                  itemCount: _holePars.length,
                  itemBuilder: (context, index) {
                    final isLastHole = index == _holePars.length - 1;
                    return Column(
                      children: [
                        Expanded(child: _buildHoleScoring(index, scores, participants, user?.uid)),
                        if (isLastHole)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _finishRound,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.emerald700,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: const Text('Finish Group Round', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
              _buildLiveLeaderboard(participants, scores),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(Map<String, dynamic> data, Map<String, dynamic> scores, String? myUid) {
    return AppBar(
      backgroundColor: const Color(0xFFF6F5F0),
      elevation: 0,
      title: Column(
        children: [
          Text(data['courseName'] ?? 'Round', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const Text('LIVE GROUP SCORING', style: TextStyle(color: AppColors.emerald700, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.listOrdered, color: AppColors.grey700),
          onPressed: () => _showFullLeaderboard(scores),
        ),
      ],
    );
  }

  Widget _buildHoleProgress() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _holePars.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (context, index) {
          final isCurrent = index == _currentHoleIndex;
          return GestureDetector(
            onTap: () => _pageController.jumpToPage(index),
            child: Container(
              width: 34,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.grey900 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isCurrent ? AppColors.grey900 : AppColors.grey200),
              ),
              alignment: Alignment.center,
              child: Text('${index + 1}', style: TextStyle(color: isCurrent ? Colors.white : AppColors.grey600, fontWeight: FontWeight.w800, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHoleScoring(int holeIndex, Map<String, dynamic> scores, List participants, String? myUid) {
    final holeNum = holeIndex + 1;
    final par = _holePars[holeIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('HOLE $holeNum', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
          Text('PAR $par', style: const TextStyle(color: AppColors.grey400, fontWeight: FontWeight.w800)),
          const Spacer(),
          
          if (widget.mode == 'INDIVIDUAL_DEVICES')
            _buildPlayerScoringTile(myUid!, holeNum, par, scores[myUid])
          else
            Expanded(
              child: ListView(
                children: participants.map((p) {
                  final uid = p['userId'] as String;
                  return _buildPlayerScoringTile(uid, holeNum, par, scores[uid]);
                }).toList(),
              ),
            ),
            
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildPlayerScoringTile(String uid, int holeNum, int par, dynamic userScoreData) {
    final holeKey = 'hole$holeNum';
    final scoreData = (userScoreData as Map<String, dynamic>? ?? {})[holeKey] as Map<String, dynamic>? ?? {};
    final score = scoreData['score'] as int? ?? par;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppColors.grey100)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppColors.grey50, child: const Icon(LucideIcons.user, color: AppColors.grey400)),
          const SizedBox(width: 16),
          Expanded(child: Text(uid == ref.watch(authStateProvider).valueOrNull?.uid ? 'You' : 'Player', style: const TextStyle(fontWeight: FontWeight.w800))),
          
          Row(
            children: [
              IconButton(icon: const Icon(LucideIcons.minusCircle), onPressed: () => _updateScore(uid, holeNum, score - 1)),
              Text('$score', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(LucideIcons.plusCircle), onPressed: () => _updateScore(uid, holeNum, score + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveLeaderboard(List participants, Map<String, dynamic> scores) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: participants.map((p) {
          final uid = p['userId'] as String;
          final userScores = scores[uid] as Map<String, dynamic>? ?? {};
          int totalToPar = 0;
          userScores.forEach((k, v) {
            final hNum = int.tryParse(k.replaceAll('hole', '')) ?? 0;
            if (hNum > 0 && hNum <= _holePars.length) {
              totalToPar += ((v['score'] as int) - _holePars[hNum - 1]);
            }
          });
          final toParText = totalToPar == 0 ? 'E' : totalToPar > 0 ? '+$totalToPar' : '$totalToPar';
          
          return Column(
            children: [
              Text(toParText, style: TextStyle(fontWeight: FontWeight.w900, color: totalToPar <= 0 ? AppColors.emerald700 : AppColors.doubleBogey)),
              Text(uid == ref.watch(authStateProvider).valueOrNull?.uid ? 'ME' : 'P${uid.substring(0, 2)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Future<void> _updateScore(String playerUid, int holeNum, int newScore) async {
    if (newScore < 1) return;
    
    await ref.read(groupSyncServiceProvider).updateHoleScore(
      firestoreRoundId: widget.groupRoundId,
      holeNumber: holeNum,
      scoreData: {
        'score': newScore,
        'par': _holePars[holeNum - 1],
      },
    );
  }

  void _finishRound() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    // Use a StreamBuilder or just a final fetch
    final snapshot = await FirebaseFirestore.instance.collection('group_rounds').doc(widget.groupRoundId).get();
    final data = snapshot.data() as Map<String, dynamic>;
    final scores = data['scores'] as Map<String, dynamic>? ?? {};
    final myScores = scores[user.uid] as Map<String, dynamic>? ?? {};

    // 1. Calculate totals for ME
    int totalScore = 0;
    _holePars.asMap().forEach((idx, par) {
      final hScore = (myScores['hole${idx + 1}'] as Map<String, dynamic>? ?? {})['score'] as int? ?? par;
      totalScore += hScore;
    });
    
    int coursePar = _holePars.reduce((a, b) => a + b);
    
    // 2. Save to Local DB
    final db = ref.read(databaseProvider);
    final roundId = await db.into(db.rounds).insert(
      RoundsCompanion.insert(
        firestoreId: drift.Value(widget.groupRoundId),
        courseId: widget.courseId,
        courseName: drift.Value(_course?.name ?? 'Unknown'),
        holesPlayed: drift.Value(_holePars.length),
        tee: const drift.Value('Group'),
        totalScore: totalScore,
        coursePar: coursePar,
        scoreVsPar: totalScore - coursePar,
        playedAt: drift.Value(DateTime.now()),
        userId: drift.Value(user.uid),
      ),
    );

    // 3. Save Hole Scores locally
    for (int i = 0; i < _holePars.length; i++) {
       final hScore = (myScores['hole${i+1}'] as Map<String, dynamic>? ?? {})['score'] as int? ?? _holePars[i];
       await db.into(db.holeScores).insert(
         HoleScoresCompanion.insert(
           roundId: roundId,
           holeNumber: i + 1,
           par: _holePars[i],
           score: hScore,
           groupRoundId: drift.Value(0), // Placeholder for local reference if needed
         )
       );
    }

    // 4. Finalize in Firestore if Captain
    if (data['captainId'] == user.uid) {
      await ref.read(groupSyncServiceProvider).finalizeRound(widget.groupRoundId);
    }

    if (mounted) {
      context.go('/');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group Round Saved!')));
    }
  }

  void _showFullLeaderboard(Map<String, dynamic> scores) {
    // Show a modal with all players and their hole-by-hole grid
  }
}
