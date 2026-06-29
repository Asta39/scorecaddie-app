import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/loading_spinner.dart';

class LiveLeaderboardScreen extends ConsumerStatefulWidget {
  final String competitionId;
  const LiveLeaderboardScreen({super.key, required this.competitionId});

  @override
  ConsumerState<LiveLeaderboardScreen> createState() => _LiveLeaderboardScreenState();
}

class _LiveLeaderboardScreenState extends ConsumerState<LiveLeaderboardScreen> {
  final _supabase = Supabase.instance.client;
  RealtimeChannel? _subscription;
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _supabase.removeChannel(_subscription!);
    super.dispose();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final data = await _supabase
          .from('competition_leaderboard')
          .select()
          .eq('competition_id', widget.competitionId)
          .order('position', ascending: true);

      setState(() {
        _leaderboardData = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealtimeSubscription() {
    _subscription = _supabase
        .channel('public:competition_results')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'competition_results',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'competition_id',
            value: widget.competitionId,
          ),
          callback: (payload) {
            // Re-fetch the view when underlying results change
            _fetchLeaderboard();
          },
        )
        .subscribe();
  }

  Widget _buildScoreText(Map<String, dynamic> row) {
    final compType = row['competition_type'] as String?;
    
    if (compType == 'stableford' || compType == 'betterball' || compType == 'bogey') {
      final pts = row['stableford_points'];
      return Text(
        pts != null ? '$pts pts' : '-',
        style: const TextStyle(fontWeight: FontWeight.bold),
      );
    } else {
      final net = row['net_score'];
      final gross = row['gross_score'];
      if (net == null) return const Text('-');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$net Net', style: const TextStyle(fontWeight: FontWeight.bold)),
          if (gross != null)
            Text('$gross Gross', style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Leaderboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchLeaderboard();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingSpinner())
          : _leaderboardData.isEmpty
              ? const Center(child: Text('No scores recorded yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaderboardData.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final row = _leaderboardData[index];
                    final position = row['position']?.toString() ?? '-';
                    final name = row['full_name'] ?? 'Unknown Golfer';
                    final flight = row['flight_name'];

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.emerald100,
                        child: Text(
                          position,
                          style: const TextStyle(
                            color: AppColors.emerald700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: flight != null ? Text('Flight: $flight') : null,
                      trailing: _buildScoreText(row),
                    );
                  },
                ),
    );
  }
}
