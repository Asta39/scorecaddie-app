// Competition domain models
// These are plain Dart classes that mirror the Supabase competition schema.

class Competition {
  final String id;
  final String clubId;
  final String name;
  final String? description;
  final String competitionType; // strokeplay | stableford | matchplay | betterball | foursome | bogey
  final String status; // upcoming | open_for_entry | in_progress | closed | completed | cancelled
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? entryDeadline;
  final double entryFee;
  final String currency;
  final Map<String, dynamic> rulesConfig;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Aggregated fields (from joins)
  final int? entryCount;
  final String? clubName;

  const Competition({
    required this.id,
    required this.clubId,
    required this.name,
    this.description,
    required this.competitionType,
    required this.status,
    required this.startDate,
    this.endDate,
    this.entryDeadline,
    this.entryFee = 0,
    this.currency = 'KES',
    this.rulesConfig = const {},
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.entryCount,
    this.clubName,
  });

  factory Competition.fromJson(Map<String, dynamic> json) {
    return Competition(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      competitionType: json['competition_type'] as String? ?? 'strokeplay',
      status: json['status'] as String? ?? 'upcoming',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      entryDeadline: json['entry_deadline'] != null
          ? DateTime.parse(json['entry_deadline'] as String)
          : null,
      entryFee: (json['entry_fee'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'KES',
      rulesConfig: (json['rules_config'] as Map<String, dynamic>?) ?? {},
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      entryCount: json['entry_count'] as int?,
      clubName: json['club_name'] as String?,
    );
  }

  String get formatLabel {
    switch (competitionType) {
      case 'stableford':
        return 'Stableford';
      case 'matchplay':
        return 'Match Play';
      case 'betterball':
        return 'Better Ball';
      case 'foursome':
        return 'Foursome';
      case 'bogey':
        return 'Bogey';
      default:
        return 'Stroke Play';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'open_for_entry':
        return 'Open for Entry';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'closed':
        return 'Closed';
      default:
        return 'Upcoming';
    }
  }

  bool get isOpenForEntry => status == 'open_for_entry';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';

  Competition copyWith({
    String? id,
    String? clubId,
    String? name,
    String? description,
    String? competitionType,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? entryDeadline,
    double? entryFee,
    String? currency,
    Map<String, dynamic>? rulesConfig,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? entryCount,
    String? clubName,
  }) {
    return Competition(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      description: description ?? this.description,
      competitionType: competitionType ?? this.competitionType,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      entryDeadline: entryDeadline ?? this.entryDeadline,
      entryFee: entryFee ?? this.entryFee,
      currency: currency ?? this.currency,
      rulesConfig: rulesConfig ?? this.rulesConfig,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      entryCount: entryCount ?? this.entryCount,
      clubName: clubName ?? this.clubName,
    );
  }
}

class CompetitionEntry {
  final String id;
  final String competitionId;
  final String playerId;
  final double? playingHandicap;
  final String? flightName;
  final String? teeColor;
  final String entryStatus; // pending | confirmed | withdrawn | disqualified
  final String paymentStatus; // unpaid | paid | waived | refunded
  final String? confirmedBy;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  // Joined fields
  final String? playerName;
  final double? playerHandicap;
  final String? playerAvatarUrl;

  const CompetitionEntry({
    required this.id,
    required this.competitionId,
    required this.playerId,
    this.playingHandicap,
    this.flightName,
    this.teeColor,
    required this.entryStatus,
    required this.paymentStatus,
    this.confirmedBy,
    this.confirmedAt,
    required this.createdAt,
    this.playerName,
    this.playerHandicap,
    this.playerAvatarUrl,
  });

  factory CompetitionEntry.fromJson(Map<String, dynamic> json) {
    return CompetitionEntry(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      playerId: json['player_id'] as String,
      playingHandicap: (json['playing_handicap'] as num?)?.toDouble(),
      flightName: json['flight_name'] as String?,
      teeColor: json['tee_color'] as String?,
      entryStatus: json['entry_status'] as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      confirmedBy: json['confirmed_by'] as String?,
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      playerName: json['full_name'] as String?,
      playerHandicap: (json['handicap_index'] as num?)?.toDouble(),
      playerAvatarUrl: json['avatar_url'] as String?,
    );
  }

  bool get isConfirmed => entryStatus == 'confirmed';
  bool get isPending => entryStatus == 'pending';
}

class StartingSheetRow {
  final String id;
  final String competitionId;
  final String entryId;
  final DateTime teeTime;
  final int teeNumber;
  final int groupNumber;
  final int roundNumber;

  // Joined from view
  final String? playerId;
  final String? playerName;
  final double? handicapIndex;
  final double? playingHandicap;
  final String? teeColor;
  final String? flightName;
  final String? entryStatus;

  const StartingSheetRow({
    required this.id,
    required this.competitionId,
    required this.entryId,
    required this.teeTime,
    required this.teeNumber,
    required this.groupNumber,
    required this.roundNumber,
    this.playerId,
    this.playerName,
    this.handicapIndex,
    this.playingHandicap,
    this.teeColor,
    this.flightName,
    this.entryStatus,
  });

  factory StartingSheetRow.fromJson(Map<String, dynamic> json) {
    return StartingSheetRow(
      id: json['id'] as String,
      competitionId: json['competition_id'] as String,
      entryId: json['entry_id'] as String,
      teeTime: DateTime.parse(json['tee_time'] as String).toLocal(),
      teeNumber: json['tee_number'] as int? ?? 1,
      groupNumber: json['group_number'] as int? ?? 1,
      roundNumber: json['round_number'] as int? ?? 1,
      playerId: json['player_id'] as String?,
      playerName: json['full_name'] as String?,
      handicapIndex: (json['handicap_index'] as num?)?.toDouble(),
      playingHandicap: (json['playing_handicap'] as num?)?.toDouble(),
      teeColor: json['tee_color'] as String?,
      flightName: json['flight_name'] as String?,
      entryStatus: json['entry_status'] as String?,
    );
  }
}

class LeaderboardRow {
  final String competitionId;
  final int? position;
  final String playerId;
  final String? fullName;
  final double? handicapIndex;
  final double? playingHandicap;
  final String? flightName;
  final int? grossScore;
  final double? netScore;
  final int? stablefordPoints;
  final String resultStatus; // active | dsq | dnf | wdr
  final bool certified;
  final String competitionType;
  final String competitionName;
  final String competitionStatus;
  final DateTime startDate;

  const LeaderboardRow({
    required this.competitionId,
    this.position,
    required this.playerId,
    this.fullName,
    this.handicapIndex,
    this.playingHandicap,
    this.flightName,
    this.grossScore,
    this.netScore,
    this.stablefordPoints,
    required this.resultStatus,
    required this.certified,
    required this.competitionType,
    required this.competitionName,
    required this.competitionStatus,
    required this.startDate,
  });

  factory LeaderboardRow.fromJson(Map<String, dynamic> json) {
    return LeaderboardRow(
      competitionId: json['competition_id'] as String,
      position: json['position'] as int?,
      playerId: json['player_id'] as String,
      fullName: json['full_name'] as String?,
      handicapIndex: (json['handicap_index'] as num?)?.toDouble(),
      playingHandicap: (json['playing_handicap'] as num?)?.toDouble(),
      flightName: json['flight_name'] as String?,
      grossScore: json['gross_score'] as int?,
      netScore: (json['net_score'] as num?)?.toDouble(),
      stablefordPoints: json['stableford_points'] as int?,
      resultStatus: json['result_status'] as String? ?? 'active',
      certified: json['certified'] as bool? ?? false,
      competitionType: json['competition_type'] as String? ?? 'strokeplay',
      competitionName: json['competition_name'] as String? ?? '',
      competitionStatus: json['competition_status'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
    );
  }

  String get displayScore {
    if (resultStatus == 'dsq') return 'DQ';
    if (resultStatus == 'dnf') return 'DNF';
    if (resultStatus == 'wdr') return 'WDR';
    if (competitionType == 'stableford') {
      return stablefordPoints != null ? '$stablefordPoints pts' : '-';
    }
    return netScore != null ? netScore!.toStringAsFixed(0) : '-';
  }
}
