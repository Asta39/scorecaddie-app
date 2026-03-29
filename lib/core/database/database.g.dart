// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UserProfilesTable extends UserProfiles
    with TableInfo<$UserProfilesTable, UserProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _firebaseUidMeta = const VerificationMeta(
    'firebaseUid',
  );
  @override
  late final GeneratedColumn<String> firebaseUid = GeneratedColumn<String>(
    'firebase_uid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Golfer'),
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _handicapMeta = const VerificationMeta(
    'handicap',
  );
  @override
  late final GeneratedColumn<double> handicap = GeneratedColumn<double>(
    'handicap',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeCourseIdMeta = const VerificationMeta(
    'homeCourseId',
  );
  @override
  late final GeneratedColumn<int> homeCourseId = GeneratedColumn<int>(
    'home_course_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeCourseNameMeta = const VerificationMeta(
    'homeCourseName',
  );
  @override
  late final GeneratedColumn<String> homeCourseName = GeneratedColumn<String>(
    'home_course_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skillLevelMeta = const VerificationMeta(
    'skillLevel',
  );
  @override
  late final GeneratedColumn<String> skillLevel = GeneratedColumn<String>(
    'skill_level',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _preferredTeesMeta = const VerificationMeta(
    'preferredTees',
  );
  @override
  late final GeneratedColumn<String> preferredTees = GeneratedColumn<String>(
    'preferred_tees',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playStyleMeta = const VerificationMeta(
    'playStyle',
  );
  @override
  late final GeneratedColumn<String> playStyle = GeneratedColumn<String>(
    'play_style',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<String> units = GeneratedColumn<String>(
    'units',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Yards'),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('System'),
  );
  static const VerificationMeta _privacyLevelMeta = const VerificationMeta(
    'privacyLevel',
  );
  @override
  late final GeneratedColumn<String> privacyLevel = GeneratedColumn<String>(
    'privacy_level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('Private'),
  );
  static const VerificationMeta _badgesJsonMeta = const VerificationMeta(
    'badgesJson',
  );
  @override
  late final GeneratedColumn<String> badgesJson = GeneratedColumn<String>(
    'badges_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _profileCompleteMeta = const VerificationMeta(
    'profileComplete',
  );
  @override
  late final GeneratedColumn<bool> profileComplete = GeneratedColumn<bool>(
    'profile_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("profile_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firebaseUid,
    email,
    name,
    avatarUrl,
    handicap,
    homeCourseId,
    homeCourseName,
    skillLevel,
    preferredTees,
    playStyle,
    units,
    themeMode,
    privacyLevel,
    badgesJson,
    role,
    profileComplete,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('firebase_uid')) {
      context.handle(
        _firebaseUidMeta,
        firebaseUid.isAcceptableOrUnknown(
          data['firebase_uid']!,
          _firebaseUidMeta,
        ),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('handicap')) {
      context.handle(
        _handicapMeta,
        handicap.isAcceptableOrUnknown(data['handicap']!, _handicapMeta),
      );
    }
    if (data.containsKey('home_course_id')) {
      context.handle(
        _homeCourseIdMeta,
        homeCourseId.isAcceptableOrUnknown(
          data['home_course_id']!,
          _homeCourseIdMeta,
        ),
      );
    }
    if (data.containsKey('home_course_name')) {
      context.handle(
        _homeCourseNameMeta,
        homeCourseName.isAcceptableOrUnknown(
          data['home_course_name']!,
          _homeCourseNameMeta,
        ),
      );
    }
    if (data.containsKey('skill_level')) {
      context.handle(
        _skillLevelMeta,
        skillLevel.isAcceptableOrUnknown(data['skill_level']!, _skillLevelMeta),
      );
    }
    if (data.containsKey('preferred_tees')) {
      context.handle(
        _preferredTeesMeta,
        preferredTees.isAcceptableOrUnknown(
          data['preferred_tees']!,
          _preferredTeesMeta,
        ),
      );
    }
    if (data.containsKey('play_style')) {
      context.handle(
        _playStyleMeta,
        playStyle.isAcceptableOrUnknown(data['play_style']!, _playStyleMeta),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    }
    if (data.containsKey('privacy_level')) {
      context.handle(
        _privacyLevelMeta,
        privacyLevel.isAcceptableOrUnknown(
          data['privacy_level']!,
          _privacyLevelMeta,
        ),
      );
    }
    if (data.containsKey('badges_json')) {
      context.handle(
        _badgesJsonMeta,
        badgesJson.isAcceptableOrUnknown(data['badges_json']!, _badgesJsonMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('profile_complete')) {
      context.handle(
        _profileCompleteMeta,
        profileComplete.isAcceptableOrUnknown(
          data['profile_complete']!,
          _profileCompleteMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      firebaseUid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firebase_uid'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      handicap: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}handicap'],
      ),
      homeCourseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}home_course_id'],
      ),
      homeCourseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home_course_name'],
      ),
      skillLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_level'],
      ),
      preferredTees: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_tees'],
      ),
      playStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}play_style'],
      ),
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}units'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme_mode'],
      )!,
      privacyLevel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}privacy_level'],
      )!,
      badgesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}badges_json'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      profileComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}profile_complete'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserProfilesTable createAlias(String alias) {
    return $UserProfilesTable(attachedDatabase, alias);
  }
}

class UserProfile extends DataClass implements Insertable<UserProfile> {
  final int id;
  final String? firebaseUid;
  final String? email;
  final String name;
  final String? avatarUrl;
  final double? handicap;
  final int? homeCourseId;
  final String? homeCourseName;
  final String? skillLevel;
  final String? preferredTees;
  final String? playStyle;
  final String units;
  final String themeMode;
  final String privacyLevel;
  final String badgesJson;
  final String? role;
  final bool profileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  const UserProfile({
    required this.id,
    this.firebaseUid,
    this.email,
    required this.name,
    this.avatarUrl,
    this.handicap,
    this.homeCourseId,
    this.homeCourseName,
    this.skillLevel,
    this.preferredTees,
    this.playStyle,
    required this.units,
    required this.themeMode,
    required this.privacyLevel,
    required this.badgesJson,
    this.role,
    required this.profileComplete,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || firebaseUid != null) {
      map['firebase_uid'] = Variable<String>(firebaseUid);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || handicap != null) {
      map['handicap'] = Variable<double>(handicap);
    }
    if (!nullToAbsent || homeCourseId != null) {
      map['home_course_id'] = Variable<int>(homeCourseId);
    }
    if (!nullToAbsent || homeCourseName != null) {
      map['home_course_name'] = Variable<String>(homeCourseName);
    }
    if (!nullToAbsent || skillLevel != null) {
      map['skill_level'] = Variable<String>(skillLevel);
    }
    if (!nullToAbsent || preferredTees != null) {
      map['preferred_tees'] = Variable<String>(preferredTees);
    }
    if (!nullToAbsent || playStyle != null) {
      map['play_style'] = Variable<String>(playStyle);
    }
    map['units'] = Variable<String>(units);
    map['theme_mode'] = Variable<String>(themeMode);
    map['privacy_level'] = Variable<String>(privacyLevel);
    map['badges_json'] = Variable<String>(badgesJson);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    map['profile_complete'] = Variable<bool>(profileComplete);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  UserProfilesCompanion toCompanion(bool nullToAbsent) {
    return UserProfilesCompanion(
      id: Value(id),
      firebaseUid: firebaseUid == null && nullToAbsent
          ? const Value.absent()
          : Value(firebaseUid),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      name: Value(name),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      handicap: handicap == null && nullToAbsent
          ? const Value.absent()
          : Value(handicap),
      homeCourseId: homeCourseId == null && nullToAbsent
          ? const Value.absent()
          : Value(homeCourseId),
      homeCourseName: homeCourseName == null && nullToAbsent
          ? const Value.absent()
          : Value(homeCourseName),
      skillLevel: skillLevel == null && nullToAbsent
          ? const Value.absent()
          : Value(skillLevel),
      preferredTees: preferredTees == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredTees),
      playStyle: playStyle == null && nullToAbsent
          ? const Value.absent()
          : Value(playStyle),
      units: Value(units),
      themeMode: Value(themeMode),
      privacyLevel: Value(privacyLevel),
      badgesJson: Value(badgesJson),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      profileComplete: Value(profileComplete),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserProfile(
      id: serializer.fromJson<int>(json['id']),
      firebaseUid: serializer.fromJson<String?>(json['firebaseUid']),
      email: serializer.fromJson<String?>(json['email']),
      name: serializer.fromJson<String>(json['name']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      handicap: serializer.fromJson<double?>(json['handicap']),
      homeCourseId: serializer.fromJson<int?>(json['homeCourseId']),
      homeCourseName: serializer.fromJson<String?>(json['homeCourseName']),
      skillLevel: serializer.fromJson<String?>(json['skillLevel']),
      preferredTees: serializer.fromJson<String?>(json['preferredTees']),
      playStyle: serializer.fromJson<String?>(json['playStyle']),
      units: serializer.fromJson<String>(json['units']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      privacyLevel: serializer.fromJson<String>(json['privacyLevel']),
      badgesJson: serializer.fromJson<String>(json['badgesJson']),
      role: serializer.fromJson<String?>(json['role']),
      profileComplete: serializer.fromJson<bool>(json['profileComplete']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firebaseUid': serializer.toJson<String?>(firebaseUid),
      'email': serializer.toJson<String?>(email),
      'name': serializer.toJson<String>(name),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'handicap': serializer.toJson<double?>(handicap),
      'homeCourseId': serializer.toJson<int?>(homeCourseId),
      'homeCourseName': serializer.toJson<String?>(homeCourseName),
      'skillLevel': serializer.toJson<String?>(skillLevel),
      'preferredTees': serializer.toJson<String?>(preferredTees),
      'playStyle': serializer.toJson<String?>(playStyle),
      'units': serializer.toJson<String>(units),
      'themeMode': serializer.toJson<String>(themeMode),
      'privacyLevel': serializer.toJson<String>(privacyLevel),
      'badgesJson': serializer.toJson<String>(badgesJson),
      'role': serializer.toJson<String?>(role),
      'profileComplete': serializer.toJson<bool>(profileComplete),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  UserProfile copyWith({
    int? id,
    Value<String?> firebaseUid = const Value.absent(),
    Value<String?> email = const Value.absent(),
    String? name,
    Value<String?> avatarUrl = const Value.absent(),
    Value<double?> handicap = const Value.absent(),
    Value<int?> homeCourseId = const Value.absent(),
    Value<String?> homeCourseName = const Value.absent(),
    Value<String?> skillLevel = const Value.absent(),
    Value<String?> preferredTees = const Value.absent(),
    Value<String?> playStyle = const Value.absent(),
    String? units,
    String? themeMode,
    String? privacyLevel,
    String? badgesJson,
    Value<String?> role = const Value.absent(),
    bool? profileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    id: id ?? this.id,
    firebaseUid: firebaseUid.present ? firebaseUid.value : this.firebaseUid,
    email: email.present ? email.value : this.email,
    name: name ?? this.name,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    handicap: handicap.present ? handicap.value : this.handicap,
    homeCourseId: homeCourseId.present ? homeCourseId.value : this.homeCourseId,
    homeCourseName: homeCourseName.present
        ? homeCourseName.value
        : this.homeCourseName,
    skillLevel: skillLevel.present ? skillLevel.value : this.skillLevel,
    preferredTees: preferredTees.present
        ? preferredTees.value
        : this.preferredTees,
    playStyle: playStyle.present ? playStyle.value : this.playStyle,
    units: units ?? this.units,
    themeMode: themeMode ?? this.themeMode,
    privacyLevel: privacyLevel ?? this.privacyLevel,
    badgesJson: badgesJson ?? this.badgesJson,
    role: role.present ? role.value : this.role,
    profileComplete: profileComplete ?? this.profileComplete,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserProfile copyWithCompanion(UserProfilesCompanion data) {
    return UserProfile(
      id: data.id.present ? data.id.value : this.id,
      firebaseUid: data.firebaseUid.present
          ? data.firebaseUid.value
          : this.firebaseUid,
      email: data.email.present ? data.email.value : this.email,
      name: data.name.present ? data.name.value : this.name,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      handicap: data.handicap.present ? data.handicap.value : this.handicap,
      homeCourseId: data.homeCourseId.present
          ? data.homeCourseId.value
          : this.homeCourseId,
      homeCourseName: data.homeCourseName.present
          ? data.homeCourseName.value
          : this.homeCourseName,
      skillLevel: data.skillLevel.present
          ? data.skillLevel.value
          : this.skillLevel,
      preferredTees: data.preferredTees.present
          ? data.preferredTees.value
          : this.preferredTees,
      playStyle: data.playStyle.present ? data.playStyle.value : this.playStyle,
      units: data.units.present ? data.units.value : this.units,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      privacyLevel: data.privacyLevel.present
          ? data.privacyLevel.value
          : this.privacyLevel,
      badgesJson: data.badgesJson.present
          ? data.badgesJson.value
          : this.badgesJson,
      role: data.role.present ? data.role.value : this.role,
      profileComplete: data.profileComplete.present
          ? data.profileComplete.value
          : this.profileComplete,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserProfile(')
          ..write('id: $id, ')
          ..write('firebaseUid: $firebaseUid, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('handicap: $handicap, ')
          ..write('homeCourseId: $homeCourseId, ')
          ..write('homeCourseName: $homeCourseName, ')
          ..write('skillLevel: $skillLevel, ')
          ..write('preferredTees: $preferredTees, ')
          ..write('playStyle: $playStyle, ')
          ..write('units: $units, ')
          ..write('themeMode: $themeMode, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('badgesJson: $badgesJson, ')
          ..write('role: $role, ')
          ..write('profileComplete: $profileComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firebaseUid,
    email,
    name,
    avatarUrl,
    handicap,
    homeCourseId,
    homeCourseName,
    skillLevel,
    preferredTees,
    playStyle,
    units,
    themeMode,
    privacyLevel,
    badgesJson,
    role,
    profileComplete,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserProfile &&
          other.id == this.id &&
          other.firebaseUid == this.firebaseUid &&
          other.email == this.email &&
          other.name == this.name &&
          other.avatarUrl == this.avatarUrl &&
          other.handicap == this.handicap &&
          other.homeCourseId == this.homeCourseId &&
          other.homeCourseName == this.homeCourseName &&
          other.skillLevel == this.skillLevel &&
          other.preferredTees == this.preferredTees &&
          other.playStyle == this.playStyle &&
          other.units == this.units &&
          other.themeMode == this.themeMode &&
          other.privacyLevel == this.privacyLevel &&
          other.badgesJson == this.badgesJson &&
          other.role == this.role &&
          other.profileComplete == this.profileComplete &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class UserProfilesCompanion extends UpdateCompanion<UserProfile> {
  final Value<int> id;
  final Value<String?> firebaseUid;
  final Value<String?> email;
  final Value<String> name;
  final Value<String?> avatarUrl;
  final Value<double?> handicap;
  final Value<int?> homeCourseId;
  final Value<String?> homeCourseName;
  final Value<String?> skillLevel;
  final Value<String?> preferredTees;
  final Value<String?> playStyle;
  final Value<String> units;
  final Value<String> themeMode;
  final Value<String> privacyLevel;
  final Value<String> badgesJson;
  final Value<String?> role;
  final Value<bool> profileComplete;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const UserProfilesCompanion({
    this.id = const Value.absent(),
    this.firebaseUid = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.handicap = const Value.absent(),
    this.homeCourseId = const Value.absent(),
    this.homeCourseName = const Value.absent(),
    this.skillLevel = const Value.absent(),
    this.preferredTees = const Value.absent(),
    this.playStyle = const Value.absent(),
    this.units = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    this.badgesJson = const Value.absent(),
    this.role = const Value.absent(),
    this.profileComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  UserProfilesCompanion.insert({
    this.id = const Value.absent(),
    this.firebaseUid = const Value.absent(),
    this.email = const Value.absent(),
    this.name = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.handicap = const Value.absent(),
    this.homeCourseId = const Value.absent(),
    this.homeCourseName = const Value.absent(),
    this.skillLevel = const Value.absent(),
    this.preferredTees = const Value.absent(),
    this.playStyle = const Value.absent(),
    this.units = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.privacyLevel = const Value.absent(),
    this.badgesJson = const Value.absent(),
    this.role = const Value.absent(),
    this.profileComplete = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  static Insertable<UserProfile> custom({
    Expression<int>? id,
    Expression<String>? firebaseUid,
    Expression<String>? email,
    Expression<String>? name,
    Expression<String>? avatarUrl,
    Expression<double>? handicap,
    Expression<int>? homeCourseId,
    Expression<String>? homeCourseName,
    Expression<String>? skillLevel,
    Expression<String>? preferredTees,
    Expression<String>? playStyle,
    Expression<String>? units,
    Expression<String>? themeMode,
    Expression<String>? privacyLevel,
    Expression<String>? badgesJson,
    Expression<String>? role,
    Expression<bool>? profileComplete,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firebaseUid != null) 'firebase_uid': firebaseUid,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (handicap != null) 'handicap': handicap,
      if (homeCourseId != null) 'home_course_id': homeCourseId,
      if (homeCourseName != null) 'home_course_name': homeCourseName,
      if (skillLevel != null) 'skill_level': skillLevel,
      if (preferredTees != null) 'preferred_tees': preferredTees,
      if (playStyle != null) 'play_style': playStyle,
      if (units != null) 'units': units,
      if (themeMode != null) 'theme_mode': themeMode,
      if (privacyLevel != null) 'privacy_level': privacyLevel,
      if (badgesJson != null) 'badges_json': badgesJson,
      if (role != null) 'role': role,
      if (profileComplete != null) 'profile_complete': profileComplete,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  UserProfilesCompanion copyWith({
    Value<int>? id,
    Value<String?>? firebaseUid,
    Value<String?>? email,
    Value<String>? name,
    Value<String?>? avatarUrl,
    Value<double?>? handicap,
    Value<int?>? homeCourseId,
    Value<String?>? homeCourseName,
    Value<String?>? skillLevel,
    Value<String?>? preferredTees,
    Value<String?>? playStyle,
    Value<String>? units,
    Value<String>? themeMode,
    Value<String>? privacyLevel,
    Value<String>? badgesJson,
    Value<String?>? role,
    Value<bool>? profileComplete,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return UserProfilesCompanion(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      handicap: handicap ?? this.handicap,
      homeCourseId: homeCourseId ?? this.homeCourseId,
      homeCourseName: homeCourseName ?? this.homeCourseName,
      skillLevel: skillLevel ?? this.skillLevel,
      preferredTees: preferredTees ?? this.preferredTees,
      playStyle: playStyle ?? this.playStyle,
      units: units ?? this.units,
      themeMode: themeMode ?? this.themeMode,
      privacyLevel: privacyLevel ?? this.privacyLevel,
      badgesJson: badgesJson ?? this.badgesJson,
      role: role ?? this.role,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firebaseUid.present) {
      map['firebase_uid'] = Variable<String>(firebaseUid.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (handicap.present) {
      map['handicap'] = Variable<double>(handicap.value);
    }
    if (homeCourseId.present) {
      map['home_course_id'] = Variable<int>(homeCourseId.value);
    }
    if (homeCourseName.present) {
      map['home_course_name'] = Variable<String>(homeCourseName.value);
    }
    if (skillLevel.present) {
      map['skill_level'] = Variable<String>(skillLevel.value);
    }
    if (preferredTees.present) {
      map['preferred_tees'] = Variable<String>(preferredTees.value);
    }
    if (playStyle.present) {
      map['play_style'] = Variable<String>(playStyle.value);
    }
    if (units.present) {
      map['units'] = Variable<String>(units.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (privacyLevel.present) {
      map['privacy_level'] = Variable<String>(privacyLevel.value);
    }
    if (badgesJson.present) {
      map['badges_json'] = Variable<String>(badgesJson.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (profileComplete.present) {
      map['profile_complete'] = Variable<bool>(profileComplete.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserProfilesCompanion(')
          ..write('id: $id, ')
          ..write('firebaseUid: $firebaseUid, ')
          ..write('email: $email, ')
          ..write('name: $name, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('handicap: $handicap, ')
          ..write('homeCourseId: $homeCourseId, ')
          ..write('homeCourseName: $homeCourseName, ')
          ..write('skillLevel: $skillLevel, ')
          ..write('preferredTees: $preferredTees, ')
          ..write('playStyle: $playStyle, ')
          ..write('units: $units, ')
          ..write('themeMode: $themeMode, ')
          ..write('privacyLevel: $privacyLevel, ')
          ..write('badgesJson: $badgesJson, ')
          ..write('role: $role, ')
          ..write('profileComplete: $profileComplete, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $CoursesTable extends Courses with TableInfo<$CoursesTable, Course> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CoursesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalHolesMeta = const VerificationMeta(
    'totalHoles',
  );
  @override
  late final GeneratedColumn<int> totalHoles = GeneratedColumn<int>(
    'total_holes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(18),
  );
  static const VerificationMeta _par18Meta = const VerificationMeta('par18');
  @override
  late final GeneratedColumn<int> par18 = GeneratedColumn<int>(
    'par18',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _par9frontMeta = const VerificationMeta(
    'par9front',
  );
  @override
  late final GeneratedColumn<int> par9front = GeneratedColumn<int>(
    'par9front',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _par9backMeta = const VerificationMeta(
    'par9back',
  );
  @override
  late final GeneratedColumn<int> par9back = GeneratedColumn<int>(
    'par9back',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _holeParsMeta = const VerificationMeta(
    'holePars',
  );
  @override
  late final GeneratedColumn<String> holePars = GeneratedColumn<String>(
    'hole_pars',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _teeDataMeta = const VerificationMeta(
    'teeData',
  );
  @override
  late final GeneratedColumn<String> teeData = GeneratedColumn<String>(
    'tee_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _isUserEditedMeta = const VerificationMeta(
    'isUserEdited',
  );
  @override
  late final GeneratedColumn<bool> isUserEdited = GeneratedColumn<bool>(
    'is_user_edited',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_user_edited" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firestoreId,
    userId,
    name,
    location,
    totalHoles,
    par18,
    par9front,
    par9back,
    holePars,
    teeData,
    isUserEdited,
    syncId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'courses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Course> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('total_holes')) {
      context.handle(
        _totalHolesMeta,
        totalHoles.isAcceptableOrUnknown(data['total_holes']!, _totalHolesMeta),
      );
    }
    if (data.containsKey('par18')) {
      context.handle(
        _par18Meta,
        par18.isAcceptableOrUnknown(data['par18']!, _par18Meta),
      );
    }
    if (data.containsKey('par9front')) {
      context.handle(
        _par9frontMeta,
        par9front.isAcceptableOrUnknown(data['par9front']!, _par9frontMeta),
      );
    }
    if (data.containsKey('par9back')) {
      context.handle(
        _par9backMeta,
        par9back.isAcceptableOrUnknown(data['par9back']!, _par9backMeta),
      );
    }
    if (data.containsKey('hole_pars')) {
      context.handle(
        _holeParsMeta,
        holePars.isAcceptableOrUnknown(data['hole_pars']!, _holeParsMeta),
      );
    }
    if (data.containsKey('tee_data')) {
      context.handle(
        _teeDataMeta,
        teeData.isAcceptableOrUnknown(data['tee_data']!, _teeDataMeta),
      );
    }
    if (data.containsKey('is_user_edited')) {
      context.handle(
        _isUserEditedMeta,
        isUserEdited.isAcceptableOrUnknown(
          data['is_user_edited']!,
          _isUserEditedMeta,
        ),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Course map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Course(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      )!,
      totalHoles: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_holes'],
      )!,
      par18: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}par18'],
      ),
      par9front: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}par9front'],
      ),
      par9back: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}par9back'],
      ),
      holePars: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hole_pars'],
      )!,
      teeData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tee_data'],
      )!,
      isUserEdited: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_user_edited'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CoursesTable createAlias(String alias) {
    return $CoursesTable(attachedDatabase, alias);
  }
}

class Course extends DataClass implements Insertable<Course> {
  final int id;
  final String? firestoreId;
  final String? userId;
  final String name;
  final String location;
  final int totalHoles;
  final int? par18;
  final int? par9front;
  final int? par9back;
  final String holePars;
  final String teeData;
  final bool isUserEdited;
  final String? syncId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Course({
    required this.id,
    this.firestoreId,
    this.userId,
    required this.name,
    required this.location,
    required this.totalHoles,
    this.par18,
    this.par9front,
    this.par9back,
    required this.holePars,
    required this.teeData,
    required this.isUserEdited,
    this.syncId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    map['location'] = Variable<String>(location);
    map['total_holes'] = Variable<int>(totalHoles);
    if (!nullToAbsent || par18 != null) {
      map['par18'] = Variable<int>(par18);
    }
    if (!nullToAbsent || par9front != null) {
      map['par9front'] = Variable<int>(par9front);
    }
    if (!nullToAbsent || par9back != null) {
      map['par9back'] = Variable<int>(par9back);
    }
    map['hole_pars'] = Variable<String>(holePars);
    map['tee_data'] = Variable<String>(teeData);
    map['is_user_edited'] = Variable<bool>(isUserEdited);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CoursesCompanion toCompanion(bool nullToAbsent) {
    return CoursesCompanion(
      id: Value(id),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      location: Value(location),
      totalHoles: Value(totalHoles),
      par18: par18 == null && nullToAbsent
          ? const Value.absent()
          : Value(par18),
      par9front: par9front == null && nullToAbsent
          ? const Value.absent()
          : Value(par9front),
      par9back: par9back == null && nullToAbsent
          ? const Value.absent()
          : Value(par9back),
      holePars: Value(holePars),
      teeData: Value(teeData),
      isUserEdited: Value(isUserEdited),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Course.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Course(
      id: serializer.fromJson<int>(json['id']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      location: serializer.fromJson<String>(json['location']),
      totalHoles: serializer.fromJson<int>(json['totalHoles']),
      par18: serializer.fromJson<int?>(json['par18']),
      par9front: serializer.fromJson<int?>(json['par9front']),
      par9back: serializer.fromJson<int?>(json['par9back']),
      holePars: serializer.fromJson<String>(json['holePars']),
      teeData: serializer.fromJson<String>(json['teeData']),
      isUserEdited: serializer.fromJson<bool>(json['isUserEdited']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'location': serializer.toJson<String>(location),
      'totalHoles': serializer.toJson<int>(totalHoles),
      'par18': serializer.toJson<int?>(par18),
      'par9front': serializer.toJson<int?>(par9front),
      'par9back': serializer.toJson<int?>(par9back),
      'holePars': serializer.toJson<String>(holePars),
      'teeData': serializer.toJson<String>(teeData),
      'isUserEdited': serializer.toJson<bool>(isUserEdited),
      'syncId': serializer.toJson<String?>(syncId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Course copyWith({
    int? id,
    Value<String?> firestoreId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    String? name,
    String? location,
    int? totalHoles,
    Value<int?> par18 = const Value.absent(),
    Value<int?> par9front = const Value.absent(),
    Value<int?> par9back = const Value.absent(),
    String? holePars,
    String? teeData,
    bool? isUserEdited,
    Value<String?> syncId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Course(
    id: id ?? this.id,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    location: location ?? this.location,
    totalHoles: totalHoles ?? this.totalHoles,
    par18: par18.present ? par18.value : this.par18,
    par9front: par9front.present ? par9front.value : this.par9front,
    par9back: par9back.present ? par9back.value : this.par9back,
    holePars: holePars ?? this.holePars,
    teeData: teeData ?? this.teeData,
    isUserEdited: isUserEdited ?? this.isUserEdited,
    syncId: syncId.present ? syncId.value : this.syncId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Course copyWithCompanion(CoursesCompanion data) {
    return Course(
      id: data.id.present ? data.id.value : this.id,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      location: data.location.present ? data.location.value : this.location,
      totalHoles: data.totalHoles.present
          ? data.totalHoles.value
          : this.totalHoles,
      par18: data.par18.present ? data.par18.value : this.par18,
      par9front: data.par9front.present ? data.par9front.value : this.par9front,
      par9back: data.par9back.present ? data.par9back.value : this.par9back,
      holePars: data.holePars.present ? data.holePars.value : this.holePars,
      teeData: data.teeData.present ? data.teeData.value : this.teeData,
      isUserEdited: data.isUserEdited.present
          ? data.isUserEdited.value
          : this.isUserEdited,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Course(')
          ..write('id: $id, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('totalHoles: $totalHoles, ')
          ..write('par18: $par18, ')
          ..write('par9front: $par9front, ')
          ..write('par9back: $par9back, ')
          ..write('holePars: $holePars, ')
          ..write('teeData: $teeData, ')
          ..write('isUserEdited: $isUserEdited, ')
          ..write('syncId: $syncId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firestoreId,
    userId,
    name,
    location,
    totalHoles,
    par18,
    par9front,
    par9back,
    holePars,
    teeData,
    isUserEdited,
    syncId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Course &&
          other.id == this.id &&
          other.firestoreId == this.firestoreId &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.location == this.location &&
          other.totalHoles == this.totalHoles &&
          other.par18 == this.par18 &&
          other.par9front == this.par9front &&
          other.par9back == this.par9back &&
          other.holePars == this.holePars &&
          other.teeData == this.teeData &&
          other.isUserEdited == this.isUserEdited &&
          other.syncId == this.syncId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CoursesCompanion extends UpdateCompanion<Course> {
  final Value<int> id;
  final Value<String?> firestoreId;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String> location;
  final Value<int> totalHoles;
  final Value<int?> par18;
  final Value<int?> par9front;
  final Value<int?> par9back;
  final Value<String> holePars;
  final Value<String> teeData;
  final Value<bool> isUserEdited;
  final Value<String?> syncId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const CoursesCompanion({
    this.id = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.location = const Value.absent(),
    this.totalHoles = const Value.absent(),
    this.par18 = const Value.absent(),
    this.par9front = const Value.absent(),
    this.par9back = const Value.absent(),
    this.holePars = const Value.absent(),
    this.teeData = const Value.absent(),
    this.isUserEdited = const Value.absent(),
    this.syncId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CoursesCompanion.insert({
    this.id = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.userId = const Value.absent(),
    required String name,
    this.location = const Value.absent(),
    this.totalHoles = const Value.absent(),
    this.par18 = const Value.absent(),
    this.par9front = const Value.absent(),
    this.par9back = const Value.absent(),
    this.holePars = const Value.absent(),
    this.teeData = const Value.absent(),
    this.isUserEdited = const Value.absent(),
    this.syncId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Course> custom({
    Expression<int>? id,
    Expression<String>? firestoreId,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? location,
    Expression<int>? totalHoles,
    Expression<int>? par18,
    Expression<int>? par9front,
    Expression<int>? par9back,
    Expression<String>? holePars,
    Expression<String>? teeData,
    Expression<bool>? isUserEdited,
    Expression<String>? syncId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (location != null) 'location': location,
      if (totalHoles != null) 'total_holes': totalHoles,
      if (par18 != null) 'par18': par18,
      if (par9front != null) 'par9front': par9front,
      if (par9back != null) 'par9back': par9back,
      if (holePars != null) 'hole_pars': holePars,
      if (teeData != null) 'tee_data': teeData,
      if (isUserEdited != null) 'is_user_edited': isUserEdited,
      if (syncId != null) 'sync_id': syncId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CoursesCompanion copyWith({
    Value<int>? id,
    Value<String?>? firestoreId,
    Value<String?>? userId,
    Value<String>? name,
    Value<String>? location,
    Value<int>? totalHoles,
    Value<int?>? par18,
    Value<int?>? par9front,
    Value<int?>? par9back,
    Value<String>? holePars,
    Value<String>? teeData,
    Value<bool>? isUserEdited,
    Value<String?>? syncId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return CoursesCompanion(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      location: location ?? this.location,
      totalHoles: totalHoles ?? this.totalHoles,
      par18: par18 ?? this.par18,
      par9front: par9front ?? this.par9front,
      par9back: par9back ?? this.par9back,
      holePars: holePars ?? this.holePars,
      teeData: teeData ?? this.teeData,
      isUserEdited: isUserEdited ?? this.isUserEdited,
      syncId: syncId ?? this.syncId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (totalHoles.present) {
      map['total_holes'] = Variable<int>(totalHoles.value);
    }
    if (par18.present) {
      map['par18'] = Variable<int>(par18.value);
    }
    if (par9front.present) {
      map['par9front'] = Variable<int>(par9front.value);
    }
    if (par9back.present) {
      map['par9back'] = Variable<int>(par9back.value);
    }
    if (holePars.present) {
      map['hole_pars'] = Variable<String>(holePars.value);
    }
    if (teeData.present) {
      map['tee_data'] = Variable<String>(teeData.value);
    }
    if (isUserEdited.present) {
      map['is_user_edited'] = Variable<bool>(isUserEdited.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CoursesCompanion(')
          ..write('id: $id, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('location: $location, ')
          ..write('totalHoles: $totalHoles, ')
          ..write('par18: $par18, ')
          ..write('par9front: $par9front, ')
          ..write('par9back: $par9back, ')
          ..write('holePars: $holePars, ')
          ..write('teeData: $teeData, ')
          ..write('isUserEdited: $isUserEdited, ')
          ..write('syncId: $syncId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $RoundsTable extends Rounds with TableInfo<$RoundsTable, Round> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RoundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _courseNameMeta = const VerificationMeta(
    'courseName',
  );
  @override
  late final GeneratedColumn<String> courseName = GeneratedColumn<String>(
    'course_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _holesPlayedMeta = const VerificationMeta(
    'holesPlayed',
  );
  @override
  late final GeneratedColumn<int> holesPlayed = GeneratedColumn<int>(
    'holes_played',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(18),
  );
  static const VerificationMeta _teeMeta = const VerificationMeta('tee');
  @override
  late final GeneratedColumn<String> tee = GeneratedColumn<String>(
    'tee',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _totalScoreMeta = const VerificationMeta(
    'totalScore',
  );
  @override
  late final GeneratedColumn<int> totalScore = GeneratedColumn<int>(
    'total_score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseParMeta = const VerificationMeta(
    'coursePar',
  );
  @override
  late final GeneratedColumn<int> coursePar = GeneratedColumn<int>(
    'course_par',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreVsParMeta = const VerificationMeta(
    'scoreVsPar',
  );
  @override
  late final GeneratedColumn<int> scoreVsPar = GeneratedColumn<int>(
    'score_vs_par',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _front9ScoreMeta = const VerificationMeta(
    'front9Score',
  );
  @override
  late final GeneratedColumn<int> front9Score = GeneratedColumn<int>(
    'front9_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _back9ScoreMeta = const VerificationMeta(
    'back9Score',
  );
  @override
  late final GeneratedColumn<int> back9Score = GeneratedColumn<int>(
    'back9_score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _syncIdMeta = const VerificationMeta('syncId');
  @override
  late final GeneratedColumn<String> syncId = GeneratedColumn<String>(
    'sync_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    firestoreId,
    userId,
    courseId,
    courseName,
    holesPlayed,
    tee,
    totalScore,
    coursePar,
    scoreVsPar,
    front9Score,
    back9Score,
    notes,
    syncId,
    playedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<Round> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('course_name')) {
      context.handle(
        _courseNameMeta,
        courseName.isAcceptableOrUnknown(data['course_name']!, _courseNameMeta),
      );
    }
    if (data.containsKey('holes_played')) {
      context.handle(
        _holesPlayedMeta,
        holesPlayed.isAcceptableOrUnknown(
          data['holes_played']!,
          _holesPlayedMeta,
        ),
      );
    }
    if (data.containsKey('tee')) {
      context.handle(
        _teeMeta,
        tee.isAcceptableOrUnknown(data['tee']!, _teeMeta),
      );
    }
    if (data.containsKey('total_score')) {
      context.handle(
        _totalScoreMeta,
        totalScore.isAcceptableOrUnknown(data['total_score']!, _totalScoreMeta),
      );
    } else if (isInserting) {
      context.missing(_totalScoreMeta);
    }
    if (data.containsKey('course_par')) {
      context.handle(
        _courseParMeta,
        coursePar.isAcceptableOrUnknown(data['course_par']!, _courseParMeta),
      );
    } else if (isInserting) {
      context.missing(_courseParMeta);
    }
    if (data.containsKey('score_vs_par')) {
      context.handle(
        _scoreVsParMeta,
        scoreVsPar.isAcceptableOrUnknown(
          data['score_vs_par']!,
          _scoreVsParMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scoreVsParMeta);
    }
    if (data.containsKey('front9_score')) {
      context.handle(
        _front9ScoreMeta,
        front9Score.isAcceptableOrUnknown(
          data['front9_score']!,
          _front9ScoreMeta,
        ),
      );
    }
    if (data.containsKey('back9_score')) {
      context.handle(
        _back9ScoreMeta,
        back9Score.isAcceptableOrUnknown(data['back9_score']!, _back9ScoreMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('sync_id')) {
      context.handle(
        _syncIdMeta,
        syncId.isAcceptableOrUnknown(data['sync_id']!, _syncIdMeta),
      );
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Round map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Round(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      courseName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}course_name'],
      )!,
      holesPlayed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}holes_played'],
      )!,
      tee: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tee'],
      )!,
      totalScore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_score'],
      )!,
      coursePar: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_par'],
      )!,
      scoreVsPar: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_vs_par'],
      )!,
      front9Score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}front9_score'],
      ),
      back9Score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}back9_score'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      syncId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_id'],
      ),
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $RoundsTable createAlias(String alias) {
    return $RoundsTable(attachedDatabase, alias);
  }
}

class Round extends DataClass implements Insertable<Round> {
  final int id;
  final String? firestoreId;
  final String? userId;
  final int courseId;
  final String courseName;
  final int holesPlayed;
  final String tee;
  final int totalScore;
  final int coursePar;
  final int scoreVsPar;
  final int? front9Score;
  final int? back9Score;
  final String notes;
  final String? syncId;
  final DateTime playedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Round({
    required this.id,
    this.firestoreId,
    this.userId,
    required this.courseId,
    required this.courseName,
    required this.holesPlayed,
    required this.tee,
    required this.totalScore,
    required this.coursePar,
    required this.scoreVsPar,
    this.front9Score,
    this.back9Score,
    required this.notes,
    this.syncId,
    required this.playedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['course_id'] = Variable<int>(courseId);
    map['course_name'] = Variable<String>(courseName);
    map['holes_played'] = Variable<int>(holesPlayed);
    map['tee'] = Variable<String>(tee);
    map['total_score'] = Variable<int>(totalScore);
    map['course_par'] = Variable<int>(coursePar);
    map['score_vs_par'] = Variable<int>(scoreVsPar);
    if (!nullToAbsent || front9Score != null) {
      map['front9_score'] = Variable<int>(front9Score);
    }
    if (!nullToAbsent || back9Score != null) {
      map['back9_score'] = Variable<int>(back9Score);
    }
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || syncId != null) {
      map['sync_id'] = Variable<String>(syncId);
    }
    map['played_at'] = Variable<DateTime>(playedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  RoundsCompanion toCompanion(bool nullToAbsent) {
    return RoundsCompanion(
      id: Value(id),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      courseId: Value(courseId),
      courseName: Value(courseName),
      holesPlayed: Value(holesPlayed),
      tee: Value(tee),
      totalScore: Value(totalScore),
      coursePar: Value(coursePar),
      scoreVsPar: Value(scoreVsPar),
      front9Score: front9Score == null && nullToAbsent
          ? const Value.absent()
          : Value(front9Score),
      back9Score: back9Score == null && nullToAbsent
          ? const Value.absent()
          : Value(back9Score),
      notes: Value(notes),
      syncId: syncId == null && nullToAbsent
          ? const Value.absent()
          : Value(syncId),
      playedAt: Value(playedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Round.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Round(
      id: serializer.fromJson<int>(json['id']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      userId: serializer.fromJson<String?>(json['userId']),
      courseId: serializer.fromJson<int>(json['courseId']),
      courseName: serializer.fromJson<String>(json['courseName']),
      holesPlayed: serializer.fromJson<int>(json['holesPlayed']),
      tee: serializer.fromJson<String>(json['tee']),
      totalScore: serializer.fromJson<int>(json['totalScore']),
      coursePar: serializer.fromJson<int>(json['coursePar']),
      scoreVsPar: serializer.fromJson<int>(json['scoreVsPar']),
      front9Score: serializer.fromJson<int?>(json['front9Score']),
      back9Score: serializer.fromJson<int?>(json['back9Score']),
      notes: serializer.fromJson<String>(json['notes']),
      syncId: serializer.fromJson<String?>(json['syncId']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'userId': serializer.toJson<String?>(userId),
      'courseId': serializer.toJson<int>(courseId),
      'courseName': serializer.toJson<String>(courseName),
      'holesPlayed': serializer.toJson<int>(holesPlayed),
      'tee': serializer.toJson<String>(tee),
      'totalScore': serializer.toJson<int>(totalScore),
      'coursePar': serializer.toJson<int>(coursePar),
      'scoreVsPar': serializer.toJson<int>(scoreVsPar),
      'front9Score': serializer.toJson<int?>(front9Score),
      'back9Score': serializer.toJson<int?>(back9Score),
      'notes': serializer.toJson<String>(notes),
      'syncId': serializer.toJson<String?>(syncId),
      'playedAt': serializer.toJson<DateTime>(playedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Round copyWith({
    int? id,
    Value<String?> firestoreId = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    int? courseId,
    String? courseName,
    int? holesPlayed,
    String? tee,
    int? totalScore,
    int? coursePar,
    int? scoreVsPar,
    Value<int?> front9Score = const Value.absent(),
    Value<int?> back9Score = const Value.absent(),
    String? notes,
    Value<String?> syncId = const Value.absent(),
    DateTime? playedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Round(
    id: id ?? this.id,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    userId: userId.present ? userId.value : this.userId,
    courseId: courseId ?? this.courseId,
    courseName: courseName ?? this.courseName,
    holesPlayed: holesPlayed ?? this.holesPlayed,
    tee: tee ?? this.tee,
    totalScore: totalScore ?? this.totalScore,
    coursePar: coursePar ?? this.coursePar,
    scoreVsPar: scoreVsPar ?? this.scoreVsPar,
    front9Score: front9Score.present ? front9Score.value : this.front9Score,
    back9Score: back9Score.present ? back9Score.value : this.back9Score,
    notes: notes ?? this.notes,
    syncId: syncId.present ? syncId.value : this.syncId,
    playedAt: playedAt ?? this.playedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Round copyWithCompanion(RoundsCompanion data) {
    return Round(
      id: data.id.present ? data.id.value : this.id,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      userId: data.userId.present ? data.userId.value : this.userId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      courseName: data.courseName.present
          ? data.courseName.value
          : this.courseName,
      holesPlayed: data.holesPlayed.present
          ? data.holesPlayed.value
          : this.holesPlayed,
      tee: data.tee.present ? data.tee.value : this.tee,
      totalScore: data.totalScore.present
          ? data.totalScore.value
          : this.totalScore,
      coursePar: data.coursePar.present ? data.coursePar.value : this.coursePar,
      scoreVsPar: data.scoreVsPar.present
          ? data.scoreVsPar.value
          : this.scoreVsPar,
      front9Score: data.front9Score.present
          ? data.front9Score.value
          : this.front9Score,
      back9Score: data.back9Score.present
          ? data.back9Score.value
          : this.back9Score,
      notes: data.notes.present ? data.notes.value : this.notes,
      syncId: data.syncId.present ? data.syncId.value : this.syncId,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Round(')
          ..write('id: $id, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('userId: $userId, ')
          ..write('courseId: $courseId, ')
          ..write('courseName: $courseName, ')
          ..write('holesPlayed: $holesPlayed, ')
          ..write('tee: $tee, ')
          ..write('totalScore: $totalScore, ')
          ..write('coursePar: $coursePar, ')
          ..write('scoreVsPar: $scoreVsPar, ')
          ..write('front9Score: $front9Score, ')
          ..write('back9Score: $back9Score, ')
          ..write('notes: $notes, ')
          ..write('syncId: $syncId, ')
          ..write('playedAt: $playedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    firestoreId,
    userId,
    courseId,
    courseName,
    holesPlayed,
    tee,
    totalScore,
    coursePar,
    scoreVsPar,
    front9Score,
    back9Score,
    notes,
    syncId,
    playedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Round &&
          other.id == this.id &&
          other.firestoreId == this.firestoreId &&
          other.userId == this.userId &&
          other.courseId == this.courseId &&
          other.courseName == this.courseName &&
          other.holesPlayed == this.holesPlayed &&
          other.tee == this.tee &&
          other.totalScore == this.totalScore &&
          other.coursePar == this.coursePar &&
          other.scoreVsPar == this.scoreVsPar &&
          other.front9Score == this.front9Score &&
          other.back9Score == this.back9Score &&
          other.notes == this.notes &&
          other.syncId == this.syncId &&
          other.playedAt == this.playedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RoundsCompanion extends UpdateCompanion<Round> {
  final Value<int> id;
  final Value<String?> firestoreId;
  final Value<String?> userId;
  final Value<int> courseId;
  final Value<String> courseName;
  final Value<int> holesPlayed;
  final Value<String> tee;
  final Value<int> totalScore;
  final Value<int> coursePar;
  final Value<int> scoreVsPar;
  final Value<int?> front9Score;
  final Value<int?> back9Score;
  final Value<String> notes;
  final Value<String?> syncId;
  final Value<DateTime> playedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const RoundsCompanion({
    this.id = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.userId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.courseName = const Value.absent(),
    this.holesPlayed = const Value.absent(),
    this.tee = const Value.absent(),
    this.totalScore = const Value.absent(),
    this.coursePar = const Value.absent(),
    this.scoreVsPar = const Value.absent(),
    this.front9Score = const Value.absent(),
    this.back9Score = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  RoundsCompanion.insert({
    this.id = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.userId = const Value.absent(),
    required int courseId,
    this.courseName = const Value.absent(),
    this.holesPlayed = const Value.absent(),
    this.tee = const Value.absent(),
    required int totalScore,
    required int coursePar,
    required int scoreVsPar,
    this.front9Score = const Value.absent(),
    this.back9Score = const Value.absent(),
    this.notes = const Value.absent(),
    this.syncId = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : courseId = Value(courseId),
       totalScore = Value(totalScore),
       coursePar = Value(coursePar),
       scoreVsPar = Value(scoreVsPar);
  static Insertable<Round> custom({
    Expression<int>? id,
    Expression<String>? firestoreId,
    Expression<String>? userId,
    Expression<int>? courseId,
    Expression<String>? courseName,
    Expression<int>? holesPlayed,
    Expression<String>? tee,
    Expression<int>? totalScore,
    Expression<int>? coursePar,
    Expression<int>? scoreVsPar,
    Expression<int>? front9Score,
    Expression<int>? back9Score,
    Expression<String>? notes,
    Expression<String>? syncId,
    Expression<DateTime>? playedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (userId != null) 'user_id': userId,
      if (courseId != null) 'course_id': courseId,
      if (courseName != null) 'course_name': courseName,
      if (holesPlayed != null) 'holes_played': holesPlayed,
      if (tee != null) 'tee': tee,
      if (totalScore != null) 'total_score': totalScore,
      if (coursePar != null) 'course_par': coursePar,
      if (scoreVsPar != null) 'score_vs_par': scoreVsPar,
      if (front9Score != null) 'front9_score': front9Score,
      if (back9Score != null) 'back9_score': back9Score,
      if (notes != null) 'notes': notes,
      if (syncId != null) 'sync_id': syncId,
      if (playedAt != null) 'played_at': playedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  RoundsCompanion copyWith({
    Value<int>? id,
    Value<String?>? firestoreId,
    Value<String?>? userId,
    Value<int>? courseId,
    Value<String>? courseName,
    Value<int>? holesPlayed,
    Value<String>? tee,
    Value<int>? totalScore,
    Value<int>? coursePar,
    Value<int>? scoreVsPar,
    Value<int?>? front9Score,
    Value<int?>? back9Score,
    Value<String>? notes,
    Value<String?>? syncId,
    Value<DateTime>? playedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return RoundsCompanion(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      holesPlayed: holesPlayed ?? this.holesPlayed,
      tee: tee ?? this.tee,
      totalScore: totalScore ?? this.totalScore,
      coursePar: coursePar ?? this.coursePar,
      scoreVsPar: scoreVsPar ?? this.scoreVsPar,
      front9Score: front9Score ?? this.front9Score,
      back9Score: back9Score ?? this.back9Score,
      notes: notes ?? this.notes,
      syncId: syncId ?? this.syncId,
      playedAt: playedAt ?? this.playedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (courseName.present) {
      map['course_name'] = Variable<String>(courseName.value);
    }
    if (holesPlayed.present) {
      map['holes_played'] = Variable<int>(holesPlayed.value);
    }
    if (tee.present) {
      map['tee'] = Variable<String>(tee.value);
    }
    if (totalScore.present) {
      map['total_score'] = Variable<int>(totalScore.value);
    }
    if (coursePar.present) {
      map['course_par'] = Variable<int>(coursePar.value);
    }
    if (scoreVsPar.present) {
      map['score_vs_par'] = Variable<int>(scoreVsPar.value);
    }
    if (front9Score.present) {
      map['front9_score'] = Variable<int>(front9Score.value);
    }
    if (back9Score.present) {
      map['back9_score'] = Variable<int>(back9Score.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (syncId.present) {
      map['sync_id'] = Variable<String>(syncId.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RoundsCompanion(')
          ..write('id: $id, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('userId: $userId, ')
          ..write('courseId: $courseId, ')
          ..write('courseName: $courseName, ')
          ..write('holesPlayed: $holesPlayed, ')
          ..write('tee: $tee, ')
          ..write('totalScore: $totalScore, ')
          ..write('coursePar: $coursePar, ')
          ..write('scoreVsPar: $scoreVsPar, ')
          ..write('front9Score: $front9Score, ')
          ..write('back9Score: $back9Score, ')
          ..write('notes: $notes, ')
          ..write('syncId: $syncId, ')
          ..write('playedAt: $playedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $GroupRoundsTable extends GroupRounds
    with TableInfo<$GroupRoundsTable, GroupRound> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupRoundsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _roundCodeMeta = const VerificationMeta(
    'roundCode',
  );
  @override
  late final GeneratedColumn<String> roundCode = GeneratedColumn<String>(
    'round_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _captainIdMeta = const VerificationMeta(
    'captainId',
  );
  @override
  late final GeneratedColumn<String> captainId = GeneratedColumn<String>(
    'captain_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _courseIdMeta = const VerificationMeta(
    'courseId',
  );
  @override
  late final GeneratedColumn<int> courseId = GeneratedColumn<int>(
    'course_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES courses (id)',
    ),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDING'),
  );
  static const VerificationMeta _scoringModeMeta = const VerificationMeta(
    'scoringMode',
  );
  @override
  late final GeneratedColumn<String> scoringMode = GeneratedColumn<String>(
    'scoring_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INDIVIDUAL_DEVICES'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roundCode,
    captainId,
    courseId,
    status,
    scoringMode,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_rounds';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRound> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('round_code')) {
      context.handle(
        _roundCodeMeta,
        roundCode.isAcceptableOrUnknown(data['round_code']!, _roundCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_roundCodeMeta);
    }
    if (data.containsKey('captain_id')) {
      context.handle(
        _captainIdMeta,
        captainId.isAcceptableOrUnknown(data['captain_id']!, _captainIdMeta),
      );
    } else if (isInserting) {
      context.missing(_captainIdMeta);
    }
    if (data.containsKey('course_id')) {
      context.handle(
        _courseIdMeta,
        courseId.isAcceptableOrUnknown(data['course_id']!, _courseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_courseIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('scoring_mode')) {
      context.handle(
        _scoringModeMeta,
        scoringMode.isAcceptableOrUnknown(
          data['scoring_mode']!,
          _scoringModeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupRound map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRound(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      roundCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}round_code'],
      )!,
      captainId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}captain_id'],
      )!,
      courseId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}course_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      scoringMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scoring_mode'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GroupRoundsTable createAlias(String alias) {
    return $GroupRoundsTable(attachedDatabase, alias);
  }
}

class GroupRound extends DataClass implements Insertable<GroupRound> {
  final int id;
  final String roundCode;
  final String captainId;
  final int courseId;
  final String status;
  final String scoringMode;
  final DateTime createdAt;
  final DateTime updatedAt;
  const GroupRound({
    required this.id,
    required this.roundCode,
    required this.captainId,
    required this.courseId,
    required this.status,
    required this.scoringMode,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['round_code'] = Variable<String>(roundCode);
    map['captain_id'] = Variable<String>(captainId);
    map['course_id'] = Variable<int>(courseId);
    map['status'] = Variable<String>(status);
    map['scoring_mode'] = Variable<String>(scoringMode);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GroupRoundsCompanion toCompanion(bool nullToAbsent) {
    return GroupRoundsCompanion(
      id: Value(id),
      roundCode: Value(roundCode),
      captainId: Value(captainId),
      courseId: Value(courseId),
      status: Value(status),
      scoringMode: Value(scoringMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory GroupRound.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRound(
      id: serializer.fromJson<int>(json['id']),
      roundCode: serializer.fromJson<String>(json['roundCode']),
      captainId: serializer.fromJson<String>(json['captainId']),
      courseId: serializer.fromJson<int>(json['courseId']),
      status: serializer.fromJson<String>(json['status']),
      scoringMode: serializer.fromJson<String>(json['scoringMode']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'roundCode': serializer.toJson<String>(roundCode),
      'captainId': serializer.toJson<String>(captainId),
      'courseId': serializer.toJson<int>(courseId),
      'status': serializer.toJson<String>(status),
      'scoringMode': serializer.toJson<String>(scoringMode),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  GroupRound copyWith({
    int? id,
    String? roundCode,
    String? captainId,
    int? courseId,
    String? status,
    String? scoringMode,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => GroupRound(
    id: id ?? this.id,
    roundCode: roundCode ?? this.roundCode,
    captainId: captainId ?? this.captainId,
    courseId: courseId ?? this.courseId,
    status: status ?? this.status,
    scoringMode: scoringMode ?? this.scoringMode,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  GroupRound copyWithCompanion(GroupRoundsCompanion data) {
    return GroupRound(
      id: data.id.present ? data.id.value : this.id,
      roundCode: data.roundCode.present ? data.roundCode.value : this.roundCode,
      captainId: data.captainId.present ? data.captainId.value : this.captainId,
      courseId: data.courseId.present ? data.courseId.value : this.courseId,
      status: data.status.present ? data.status.value : this.status,
      scoringMode: data.scoringMode.present
          ? data.scoringMode.value
          : this.scoringMode,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRound(')
          ..write('id: $id, ')
          ..write('roundCode: $roundCode, ')
          ..write('captainId: $captainId, ')
          ..write('courseId: $courseId, ')
          ..write('status: $status, ')
          ..write('scoringMode: $scoringMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roundCode,
    captainId,
    courseId,
    status,
    scoringMode,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRound &&
          other.id == this.id &&
          other.roundCode == this.roundCode &&
          other.captainId == this.captainId &&
          other.courseId == this.courseId &&
          other.status == this.status &&
          other.scoringMode == this.scoringMode &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GroupRoundsCompanion extends UpdateCompanion<GroupRound> {
  final Value<int> id;
  final Value<String> roundCode;
  final Value<String> captainId;
  final Value<int> courseId;
  final Value<String> status;
  final Value<String> scoringMode;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const GroupRoundsCompanion({
    this.id = const Value.absent(),
    this.roundCode = const Value.absent(),
    this.captainId = const Value.absent(),
    this.courseId = const Value.absent(),
    this.status = const Value.absent(),
    this.scoringMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  GroupRoundsCompanion.insert({
    this.id = const Value.absent(),
    required String roundCode,
    required String captainId,
    required int courseId,
    this.status = const Value.absent(),
    this.scoringMode = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : roundCode = Value(roundCode),
       captainId = Value(captainId),
       courseId = Value(courseId);
  static Insertable<GroupRound> custom({
    Expression<int>? id,
    Expression<String>? roundCode,
    Expression<String>? captainId,
    Expression<int>? courseId,
    Expression<String>? status,
    Expression<String>? scoringMode,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roundCode != null) 'round_code': roundCode,
      if (captainId != null) 'captain_id': captainId,
      if (courseId != null) 'course_id': courseId,
      if (status != null) 'status': status,
      if (scoringMode != null) 'scoring_mode': scoringMode,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  GroupRoundsCompanion copyWith({
    Value<int>? id,
    Value<String>? roundCode,
    Value<String>? captainId,
    Value<int>? courseId,
    Value<String>? status,
    Value<String>? scoringMode,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return GroupRoundsCompanion(
      id: id ?? this.id,
      roundCode: roundCode ?? this.roundCode,
      captainId: captainId ?? this.captainId,
      courseId: courseId ?? this.courseId,
      status: status ?? this.status,
      scoringMode: scoringMode ?? this.scoringMode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (roundCode.present) {
      map['round_code'] = Variable<String>(roundCode.value);
    }
    if (captainId.present) {
      map['captain_id'] = Variable<String>(captainId.value);
    }
    if (courseId.present) {
      map['course_id'] = Variable<int>(courseId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (scoringMode.present) {
      map['scoring_mode'] = Variable<String>(scoringMode.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupRoundsCompanion(')
          ..write('id: $id, ')
          ..write('roundCode: $roundCode, ')
          ..write('captainId: $captainId, ')
          ..write('courseId: $courseId, ')
          ..write('status: $status, ')
          ..write('scoringMode: $scoringMode, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $HoleScoresTable extends HoleScores
    with TableInfo<$HoleScoresTable, HoleScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HoleScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _roundIdMeta = const VerificationMeta(
    'roundId',
  );
  @override
  late final GeneratedColumn<int> roundId = GeneratedColumn<int>(
    'round_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES rounds (id)',
    ),
  );
  static const VerificationMeta _holeNumberMeta = const VerificationMeta(
    'holeNumber',
  );
  @override
  late final GeneratedColumn<int> holeNumber = GeneratedColumn<int>(
    'hole_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parMeta = const VerificationMeta('par');
  @override
  late final GeneratedColumn<int> par = GeneratedColumn<int>(
    'par',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yardageMeta = const VerificationMeta(
    'yardage',
  );
  @override
  late final GeneratedColumn<int> yardage = GeneratedColumn<int>(
    'yardage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _puttsMeta = const VerificationMeta('putts');
  @override
  late final GeneratedColumn<int> putts = GeneratedColumn<int>(
    'putts',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fairwayHitMeta = const VerificationMeta(
    'fairwayHit',
  );
  @override
  late final GeneratedColumn<String> fairwayHit = GeneratedColumn<String>(
    'fairway_hit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _penaltiesMeta = const VerificationMeta(
    'penalties',
  );
  @override
  late final GeneratedColumn<int> penalties = GeneratedColumn<int>(
    'penalties',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupRoundIdMeta = const VerificationMeta(
    'groupRoundId',
  );
  @override
  late final GeneratedColumn<int> groupRoundId = GeneratedColumn<int>(
    'group_round_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES group_rounds (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roundId,
    holeNumber,
    par,
    score,
    yardage,
    putts,
    fairwayHit,
    penalties,
    groupRoundId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'hole_scores';
  @override
  VerificationContext validateIntegrity(
    Insertable<HoleScore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('round_id')) {
      context.handle(
        _roundIdMeta,
        roundId.isAcceptableOrUnknown(data['round_id']!, _roundIdMeta),
      );
    } else if (isInserting) {
      context.missing(_roundIdMeta);
    }
    if (data.containsKey('hole_number')) {
      context.handle(
        _holeNumberMeta,
        holeNumber.isAcceptableOrUnknown(data['hole_number']!, _holeNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_holeNumberMeta);
    }
    if (data.containsKey('par')) {
      context.handle(
        _parMeta,
        par.isAcceptableOrUnknown(data['par']!, _parMeta),
      );
    } else if (isInserting) {
      context.missing(_parMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('yardage')) {
      context.handle(
        _yardageMeta,
        yardage.isAcceptableOrUnknown(data['yardage']!, _yardageMeta),
      );
    }
    if (data.containsKey('putts')) {
      context.handle(
        _puttsMeta,
        putts.isAcceptableOrUnknown(data['putts']!, _puttsMeta),
      );
    }
    if (data.containsKey('fairway_hit')) {
      context.handle(
        _fairwayHitMeta,
        fairwayHit.isAcceptableOrUnknown(data['fairway_hit']!, _fairwayHitMeta),
      );
    }
    if (data.containsKey('penalties')) {
      context.handle(
        _penaltiesMeta,
        penalties.isAcceptableOrUnknown(data['penalties']!, _penaltiesMeta),
      );
    }
    if (data.containsKey('group_round_id')) {
      context.handle(
        _groupRoundIdMeta,
        groupRoundId.isAcceptableOrUnknown(
          data['group_round_id']!,
          _groupRoundIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HoleScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HoleScore(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      roundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_id'],
      )!,
      holeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hole_number'],
      )!,
      par: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}par'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      yardage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}yardage'],
      ),
      putts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}putts'],
      ),
      fairwayHit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fairway_hit'],
      ),
      penalties: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}penalties'],
      ),
      groupRoundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_round_id'],
      ),
    );
  }

  @override
  $HoleScoresTable createAlias(String alias) {
    return $HoleScoresTable(attachedDatabase, alias);
  }
}

class HoleScore extends DataClass implements Insertable<HoleScore> {
  final int id;
  final int roundId;
  final int holeNumber;
  final int par;
  final int score;
  final int? yardage;
  final int? putts;
  final String? fairwayHit;
  final int? penalties;
  final int? groupRoundId;
  const HoleScore({
    required this.id,
    required this.roundId,
    required this.holeNumber,
    required this.par,
    required this.score,
    this.yardage,
    this.putts,
    this.fairwayHit,
    this.penalties,
    this.groupRoundId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['round_id'] = Variable<int>(roundId);
    map['hole_number'] = Variable<int>(holeNumber);
    map['par'] = Variable<int>(par);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || yardage != null) {
      map['yardage'] = Variable<int>(yardage);
    }
    if (!nullToAbsent || putts != null) {
      map['putts'] = Variable<int>(putts);
    }
    if (!nullToAbsent || fairwayHit != null) {
      map['fairway_hit'] = Variable<String>(fairwayHit);
    }
    if (!nullToAbsent || penalties != null) {
      map['penalties'] = Variable<int>(penalties);
    }
    if (!nullToAbsent || groupRoundId != null) {
      map['group_round_id'] = Variable<int>(groupRoundId);
    }
    return map;
  }

  HoleScoresCompanion toCompanion(bool nullToAbsent) {
    return HoleScoresCompanion(
      id: Value(id),
      roundId: Value(roundId),
      holeNumber: Value(holeNumber),
      par: Value(par),
      score: Value(score),
      yardage: yardage == null && nullToAbsent
          ? const Value.absent()
          : Value(yardage),
      putts: putts == null && nullToAbsent
          ? const Value.absent()
          : Value(putts),
      fairwayHit: fairwayHit == null && nullToAbsent
          ? const Value.absent()
          : Value(fairwayHit),
      penalties: penalties == null && nullToAbsent
          ? const Value.absent()
          : Value(penalties),
      groupRoundId: groupRoundId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupRoundId),
    );
  }

  factory HoleScore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HoleScore(
      id: serializer.fromJson<int>(json['id']),
      roundId: serializer.fromJson<int>(json['roundId']),
      holeNumber: serializer.fromJson<int>(json['holeNumber']),
      par: serializer.fromJson<int>(json['par']),
      score: serializer.fromJson<int>(json['score']),
      yardage: serializer.fromJson<int?>(json['yardage']),
      putts: serializer.fromJson<int?>(json['putts']),
      fairwayHit: serializer.fromJson<String?>(json['fairwayHit']),
      penalties: serializer.fromJson<int?>(json['penalties']),
      groupRoundId: serializer.fromJson<int?>(json['groupRoundId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'roundId': serializer.toJson<int>(roundId),
      'holeNumber': serializer.toJson<int>(holeNumber),
      'par': serializer.toJson<int>(par),
      'score': serializer.toJson<int>(score),
      'yardage': serializer.toJson<int?>(yardage),
      'putts': serializer.toJson<int?>(putts),
      'fairwayHit': serializer.toJson<String?>(fairwayHit),
      'penalties': serializer.toJson<int?>(penalties),
      'groupRoundId': serializer.toJson<int?>(groupRoundId),
    };
  }

  HoleScore copyWith({
    int? id,
    int? roundId,
    int? holeNumber,
    int? par,
    int? score,
    Value<int?> yardage = const Value.absent(),
    Value<int?> putts = const Value.absent(),
    Value<String?> fairwayHit = const Value.absent(),
    Value<int?> penalties = const Value.absent(),
    Value<int?> groupRoundId = const Value.absent(),
  }) => HoleScore(
    id: id ?? this.id,
    roundId: roundId ?? this.roundId,
    holeNumber: holeNumber ?? this.holeNumber,
    par: par ?? this.par,
    score: score ?? this.score,
    yardage: yardage.present ? yardage.value : this.yardage,
    putts: putts.present ? putts.value : this.putts,
    fairwayHit: fairwayHit.present ? fairwayHit.value : this.fairwayHit,
    penalties: penalties.present ? penalties.value : this.penalties,
    groupRoundId: groupRoundId.present ? groupRoundId.value : this.groupRoundId,
  );
  HoleScore copyWithCompanion(HoleScoresCompanion data) {
    return HoleScore(
      id: data.id.present ? data.id.value : this.id,
      roundId: data.roundId.present ? data.roundId.value : this.roundId,
      holeNumber: data.holeNumber.present
          ? data.holeNumber.value
          : this.holeNumber,
      par: data.par.present ? data.par.value : this.par,
      score: data.score.present ? data.score.value : this.score,
      yardage: data.yardage.present ? data.yardage.value : this.yardage,
      putts: data.putts.present ? data.putts.value : this.putts,
      fairwayHit: data.fairwayHit.present
          ? data.fairwayHit.value
          : this.fairwayHit,
      penalties: data.penalties.present ? data.penalties.value : this.penalties,
      groupRoundId: data.groupRoundId.present
          ? data.groupRoundId.value
          : this.groupRoundId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HoleScore(')
          ..write('id: $id, ')
          ..write('roundId: $roundId, ')
          ..write('holeNumber: $holeNumber, ')
          ..write('par: $par, ')
          ..write('score: $score, ')
          ..write('yardage: $yardage, ')
          ..write('putts: $putts, ')
          ..write('fairwayHit: $fairwayHit, ')
          ..write('penalties: $penalties, ')
          ..write('groupRoundId: $groupRoundId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roundId,
    holeNumber,
    par,
    score,
    yardage,
    putts,
    fairwayHit,
    penalties,
    groupRoundId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HoleScore &&
          other.id == this.id &&
          other.roundId == this.roundId &&
          other.holeNumber == this.holeNumber &&
          other.par == this.par &&
          other.score == this.score &&
          other.yardage == this.yardage &&
          other.putts == this.putts &&
          other.fairwayHit == this.fairwayHit &&
          other.penalties == this.penalties &&
          other.groupRoundId == this.groupRoundId);
}

class HoleScoresCompanion extends UpdateCompanion<HoleScore> {
  final Value<int> id;
  final Value<int> roundId;
  final Value<int> holeNumber;
  final Value<int> par;
  final Value<int> score;
  final Value<int?> yardage;
  final Value<int?> putts;
  final Value<String?> fairwayHit;
  final Value<int?> penalties;
  final Value<int?> groupRoundId;
  const HoleScoresCompanion({
    this.id = const Value.absent(),
    this.roundId = const Value.absent(),
    this.holeNumber = const Value.absent(),
    this.par = const Value.absent(),
    this.score = const Value.absent(),
    this.yardage = const Value.absent(),
    this.putts = const Value.absent(),
    this.fairwayHit = const Value.absent(),
    this.penalties = const Value.absent(),
    this.groupRoundId = const Value.absent(),
  });
  HoleScoresCompanion.insert({
    this.id = const Value.absent(),
    required int roundId,
    required int holeNumber,
    required int par,
    required int score,
    this.yardage = const Value.absent(),
    this.putts = const Value.absent(),
    this.fairwayHit = const Value.absent(),
    this.penalties = const Value.absent(),
    this.groupRoundId = const Value.absent(),
  }) : roundId = Value(roundId),
       holeNumber = Value(holeNumber),
       par = Value(par),
       score = Value(score);
  static Insertable<HoleScore> custom({
    Expression<int>? id,
    Expression<int>? roundId,
    Expression<int>? holeNumber,
    Expression<int>? par,
    Expression<int>? score,
    Expression<int>? yardage,
    Expression<int>? putts,
    Expression<String>? fairwayHit,
    Expression<int>? penalties,
    Expression<int>? groupRoundId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roundId != null) 'round_id': roundId,
      if (holeNumber != null) 'hole_number': holeNumber,
      if (par != null) 'par': par,
      if (score != null) 'score': score,
      if (yardage != null) 'yardage': yardage,
      if (putts != null) 'putts': putts,
      if (fairwayHit != null) 'fairway_hit': fairwayHit,
      if (penalties != null) 'penalties': penalties,
      if (groupRoundId != null) 'group_round_id': groupRoundId,
    });
  }

  HoleScoresCompanion copyWith({
    Value<int>? id,
    Value<int>? roundId,
    Value<int>? holeNumber,
    Value<int>? par,
    Value<int>? score,
    Value<int?>? yardage,
    Value<int?>? putts,
    Value<String?>? fairwayHit,
    Value<int?>? penalties,
    Value<int?>? groupRoundId,
  }) {
    return HoleScoresCompanion(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      holeNumber: holeNumber ?? this.holeNumber,
      par: par ?? this.par,
      score: score ?? this.score,
      yardage: yardage ?? this.yardage,
      putts: putts ?? this.putts,
      fairwayHit: fairwayHit ?? this.fairwayHit,
      penalties: penalties ?? this.penalties,
      groupRoundId: groupRoundId ?? this.groupRoundId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (roundId.present) {
      map['round_id'] = Variable<int>(roundId.value);
    }
    if (holeNumber.present) {
      map['hole_number'] = Variable<int>(holeNumber.value);
    }
    if (par.present) {
      map['par'] = Variable<int>(par.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (yardage.present) {
      map['yardage'] = Variable<int>(yardage.value);
    }
    if (putts.present) {
      map['putts'] = Variable<int>(putts.value);
    }
    if (fairwayHit.present) {
      map['fairway_hit'] = Variable<String>(fairwayHit.value);
    }
    if (penalties.present) {
      map['penalties'] = Variable<int>(penalties.value);
    }
    if (groupRoundId.present) {
      map['group_round_id'] = Variable<int>(groupRoundId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HoleScoresCompanion(')
          ..write('id: $id, ')
          ..write('roundId: $roundId, ')
          ..write('holeNumber: $holeNumber, ')
          ..write('par: $par, ')
          ..write('score: $score, ')
          ..write('yardage: $yardage, ')
          ..write('putts: $putts, ')
          ..write('fairwayHit: $fairwayHit, ')
          ..write('penalties: $penalties, ')
          ..write('groupRoundId: $groupRoundId')
          ..write(')'))
        .toString();
  }
}

class $ClubsTable extends Clubs with TableInfo<$ClubsTable, Club> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClubsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loftMeta = const VerificationMeta('loft');
  @override
  late final GeneratedColumn<double> loft = GeneratedColumn<double>(
    'loft',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    type,
    brand,
    model,
    loft,
    notes,
    photoUrl,
    firestoreId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clubs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Club> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('loft')) {
      context.handle(
        _loftMeta,
        loft.isAcceptableOrUnknown(data['loft']!, _loftMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Club map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Club(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      loft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}loft'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ClubsTable createAlias(String alias) {
    return $ClubsTable(attachedDatabase, alias);
  }
}

class Club extends DataClass implements Insertable<Club> {
  final int id;
  final String userId;
  final String type;
  final String? brand;
  final String? model;
  final double? loft;
  final String? notes;
  final String? photoUrl;
  final String? firestoreId;
  final DateTime createdAt;
  const Club({
    required this.id,
    required this.userId,
    required this.type,
    this.brand,
    this.model,
    this.loft,
    this.notes,
    this.photoUrl,
    this.firestoreId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || loft != null) {
      map['loft'] = Variable<double>(loft);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ClubsCompanion toCompanion(bool nullToAbsent) {
    return ClubsCompanion(
      id: Value(id),
      userId: Value(userId),
      type: Value(type),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      loft: loft == null && nullToAbsent ? const Value.absent() : Value(loft),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      createdAt: Value(createdAt),
    );
  }

  factory Club.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Club(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      type: serializer.fromJson<String>(json['type']),
      brand: serializer.fromJson<String?>(json['brand']),
      model: serializer.fromJson<String?>(json['model']),
      loft: serializer.fromJson<double?>(json['loft']),
      notes: serializer.fromJson<String?>(json['notes']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'type': serializer.toJson<String>(type),
      'brand': serializer.toJson<String?>(brand),
      'model': serializer.toJson<String?>(model),
      'loft': serializer.toJson<double?>(loft),
      'notes': serializer.toJson<String?>(notes),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Club copyWith({
    int? id,
    String? userId,
    String? type,
    Value<String?> brand = const Value.absent(),
    Value<String?> model = const Value.absent(),
    Value<double?> loft = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> photoUrl = const Value.absent(),
    Value<String?> firestoreId = const Value.absent(),
    DateTime? createdAt,
  }) => Club(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    type: type ?? this.type,
    brand: brand.present ? brand.value : this.brand,
    model: model.present ? model.value : this.model,
    loft: loft.present ? loft.value : this.loft,
    notes: notes.present ? notes.value : this.notes,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    createdAt: createdAt ?? this.createdAt,
  );
  Club copyWithCompanion(ClubsCompanion data) {
    return Club(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      type: data.type.present ? data.type.value : this.type,
      brand: data.brand.present ? data.brand.value : this.brand,
      model: data.model.present ? data.model.value : this.model,
      loft: data.loft.present ? data.loft.value : this.loft,
      notes: data.notes.present ? data.notes.value : this.notes,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Club(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('loft: $loft, ')
          ..write('notes: $notes, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    type,
    brand,
    model,
    loft,
    notes,
    photoUrl,
    firestoreId,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Club &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.type == this.type &&
          other.brand == this.brand &&
          other.model == this.model &&
          other.loft == this.loft &&
          other.notes == this.notes &&
          other.photoUrl == this.photoUrl &&
          other.firestoreId == this.firestoreId &&
          other.createdAt == this.createdAt);
}

class ClubsCompanion extends UpdateCompanion<Club> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> type;
  final Value<String?> brand;
  final Value<String?> model;
  final Value<double?> loft;
  final Value<String?> notes;
  final Value<String?> photoUrl;
  final Value<String?> firestoreId;
  final Value<DateTime> createdAt;
  const ClubsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.type = const Value.absent(),
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.loft = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ClubsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String type,
    this.brand = const Value.absent(),
    this.model = const Value.absent(),
    this.loft = const Value.absent(),
    this.notes = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId),
       type = Value(type);
  static Insertable<Club> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? type,
    Expression<String>? brand,
    Expression<String>? model,
    Expression<double>? loft,
    Expression<String>? notes,
    Expression<String>? photoUrl,
    Expression<String>? firestoreId,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (type != null) 'type': type,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (loft != null) 'loft': loft,
      if (notes != null) 'notes': notes,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ClubsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? type,
    Value<String?>? brand,
    Value<String?>? model,
    Value<double?>? loft,
    Value<String?>? notes,
    Value<String?>? photoUrl,
    Value<String?>? firestoreId,
    Value<DateTime>? createdAt,
  }) {
    return ClubsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      loft: loft ?? this.loft,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      firestoreId: firestoreId ?? this.firestoreId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (loft.present) {
      map['loft'] = Variable<double>(loft.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClubsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('type: $type, ')
          ..write('brand: $brand, ')
          ..write('model: $model, ')
          ..write('loft: $loft, ')
          ..write('notes: $notes, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FriendsTable extends Friends with TableInfo<$FriendsTable, Friend> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FriendsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendIdMeta = const VerificationMeta(
    'friendId',
  );
  @override
  late final GeneratedColumn<String> friendId = GeneratedColumn<String>(
    'friend_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _friendNameMeta = const VerificationMeta(
    'friendName',
  );
  @override
  late final GeneratedColumn<String> friendName = GeneratedColumn<String>(
    'friend_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _friendAvatarMeta = const VerificationMeta(
    'friendAvatar',
  );
  @override
  late final GeneratedColumn<String> friendAvatar = GeneratedColumn<String>(
    'friend_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    friendId,
    friendName,
    friendAvatar,
    firestoreId,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'friends';
  @override
  VerificationContext validateIntegrity(
    Insertable<Friend> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('friend_id')) {
      context.handle(
        _friendIdMeta,
        friendId.isAcceptableOrUnknown(data['friend_id']!, _friendIdMeta),
      );
    } else if (isInserting) {
      context.missing(_friendIdMeta);
    }
    if (data.containsKey('friend_name')) {
      context.handle(
        _friendNameMeta,
        friendName.isAcceptableOrUnknown(data['friend_name']!, _friendNameMeta),
      );
    }
    if (data.containsKey('friend_avatar')) {
      context.handle(
        _friendAvatarMeta,
        friendAvatar.isAcceptableOrUnknown(
          data['friend_avatar']!,
          _friendAvatarMeta,
        ),
      );
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Friend map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Friend(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      friendId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_id'],
      )!,
      friendName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_name'],
      ),
      friendAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}friend_avatar'],
      ),
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FriendsTable createAlias(String alias) {
    return $FriendsTable(attachedDatabase, alias);
  }
}

class Friend extends DataClass implements Insertable<Friend> {
  final int id;
  final String userId;
  final String friendId;
  final String? friendName;
  final String? friendAvatar;
  final String? firestoreId;
  final DateTime addedAt;
  const Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    this.friendName,
    this.friendAvatar,
    this.firestoreId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['friend_id'] = Variable<String>(friendId);
    if (!nullToAbsent || friendName != null) {
      map['friend_name'] = Variable<String>(friendName);
    }
    if (!nullToAbsent || friendAvatar != null) {
      map['friend_avatar'] = Variable<String>(friendAvatar);
    }
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FriendsCompanion toCompanion(bool nullToAbsent) {
    return FriendsCompanion(
      id: Value(id),
      userId: Value(userId),
      friendId: Value(friendId),
      friendName: friendName == null && nullToAbsent
          ? const Value.absent()
          : Value(friendName),
      friendAvatar: friendAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(friendAvatar),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      addedAt: Value(addedAt),
    );
  }

  factory Friend.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Friend(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      friendId: serializer.fromJson<String>(json['friendId']),
      friendName: serializer.fromJson<String?>(json['friendName']),
      friendAvatar: serializer.fromJson<String?>(json['friendAvatar']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'friendId': serializer.toJson<String>(friendId),
      'friendName': serializer.toJson<String?>(friendName),
      'friendAvatar': serializer.toJson<String?>(friendAvatar),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  Friend copyWith({
    int? id,
    String? userId,
    String? friendId,
    Value<String?> friendName = const Value.absent(),
    Value<String?> friendAvatar = const Value.absent(),
    Value<String?> firestoreId = const Value.absent(),
    DateTime? addedAt,
  }) => Friend(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    friendId: friendId ?? this.friendId,
    friendName: friendName.present ? friendName.value : this.friendName,
    friendAvatar: friendAvatar.present ? friendAvatar.value : this.friendAvatar,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    addedAt: addedAt ?? this.addedAt,
  );
  Friend copyWithCompanion(FriendsCompanion data) {
    return Friend(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      friendId: data.friendId.present ? data.friendId.value : this.friendId,
      friendName: data.friendName.present
          ? data.friendName.value
          : this.friendName,
      friendAvatar: data.friendAvatar.present
          ? data.friendAvatar.value
          : this.friendAvatar,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Friend(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('friendId: $friendId, ')
          ..write('friendName: $friendName, ')
          ..write('friendAvatar: $friendAvatar, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    friendId,
    friendName,
    friendAvatar,
    firestoreId,
    addedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Friend &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.friendId == this.friendId &&
          other.friendName == this.friendName &&
          other.friendAvatar == this.friendAvatar &&
          other.firestoreId == this.firestoreId &&
          other.addedAt == this.addedAt);
}

class FriendsCompanion extends UpdateCompanion<Friend> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> friendId;
  final Value<String?> friendName;
  final Value<String?> friendAvatar;
  final Value<String?> firestoreId;
  final Value<DateTime> addedAt;
  const FriendsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.friendId = const Value.absent(),
    this.friendName = const Value.absent(),
    this.friendAvatar = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.addedAt = const Value.absent(),
  });
  FriendsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String friendId,
    this.friendName = const Value.absent(),
    this.friendAvatar = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.addedAt = const Value.absent(),
  }) : userId = Value(userId),
       friendId = Value(friendId);
  static Insertable<Friend> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? friendId,
    Expression<String>? friendName,
    Expression<String>? friendAvatar,
    Expression<String>? firestoreId,
    Expression<DateTime>? addedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (friendId != null) 'friend_id': friendId,
      if (friendName != null) 'friend_name': friendName,
      if (friendAvatar != null) 'friend_avatar': friendAvatar,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (addedAt != null) 'added_at': addedAt,
    });
  }

  FriendsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? friendId,
    Value<String?>? friendName,
    Value<String?>? friendAvatar,
    Value<String?>? firestoreId,
    Value<DateTime>? addedAt,
  }) {
    return FriendsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      friendName: friendName ?? this.friendName,
      friendAvatar: friendAvatar ?? this.friendAvatar,
      firestoreId: firestoreId ?? this.firestoreId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (friendId.present) {
      map['friend_id'] = Variable<String>(friendId.value);
    }
    if (friendName.present) {
      map['friend_name'] = Variable<String>(friendName.value);
    }
    if (friendAvatar.present) {
      map['friend_avatar'] = Variable<String>(friendAvatar.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FriendsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('friendId: $friendId, ')
          ..write('friendName: $friendName, ')
          ..write('friendAvatar: $friendAvatar, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }
}

class $GroupRoundParticipantsTable extends GroupRoundParticipants
    with TableInfo<$GroupRoundParticipantsTable, GroupRoundParticipant> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupRoundParticipantsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _groupRoundIdMeta = const VerificationMeta(
    'groupRoundId',
  );
  @override
  late final GeneratedColumn<int> groupRoundId = GeneratedColumn<int>(
    'group_round_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES group_rounds (id)',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('JOINED'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PLAYER'),
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<DateTime> joinedAt = GeneratedColumn<DateTime>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupRoundId,
    userId,
    status,
    role,
    joinedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_round_participants';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRoundParticipant> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('group_round_id')) {
      context.handle(
        _groupRoundIdMeta,
        groupRoundId.isAcceptableOrUnknown(
          data['group_round_id']!,
          _groupRoundIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_groupRoundIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupRoundParticipant map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRoundParticipant(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      groupRoundId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_round_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}joined_at'],
      )!,
    );
  }

  @override
  $GroupRoundParticipantsTable createAlias(String alias) {
    return $GroupRoundParticipantsTable(attachedDatabase, alias);
  }
}

class GroupRoundParticipant extends DataClass
    implements Insertable<GroupRoundParticipant> {
  final int id;
  final int groupRoundId;
  final String userId;
  final String status;
  final String role;
  final DateTime joinedAt;
  const GroupRoundParticipant({
    required this.id,
    required this.groupRoundId,
    required this.userId,
    required this.status,
    required this.role,
    required this.joinedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['group_round_id'] = Variable<int>(groupRoundId);
    map['user_id'] = Variable<String>(userId);
    map['status'] = Variable<String>(status);
    map['role'] = Variable<String>(role);
    map['joined_at'] = Variable<DateTime>(joinedAt);
    return map;
  }

  GroupRoundParticipantsCompanion toCompanion(bool nullToAbsent) {
    return GroupRoundParticipantsCompanion(
      id: Value(id),
      groupRoundId: Value(groupRoundId),
      userId: Value(userId),
      status: Value(status),
      role: Value(role),
      joinedAt: Value(joinedAt),
    );
  }

  factory GroupRoundParticipant.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRoundParticipant(
      id: serializer.fromJson<int>(json['id']),
      groupRoundId: serializer.fromJson<int>(json['groupRoundId']),
      userId: serializer.fromJson<String>(json['userId']),
      status: serializer.fromJson<String>(json['status']),
      role: serializer.fromJson<String>(json['role']),
      joinedAt: serializer.fromJson<DateTime>(json['joinedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'groupRoundId': serializer.toJson<int>(groupRoundId),
      'userId': serializer.toJson<String>(userId),
      'status': serializer.toJson<String>(status),
      'role': serializer.toJson<String>(role),
      'joinedAt': serializer.toJson<DateTime>(joinedAt),
    };
  }

  GroupRoundParticipant copyWith({
    int? id,
    int? groupRoundId,
    String? userId,
    String? status,
    String? role,
    DateTime? joinedAt,
  }) => GroupRoundParticipant(
    id: id ?? this.id,
    groupRoundId: groupRoundId ?? this.groupRoundId,
    userId: userId ?? this.userId,
    status: status ?? this.status,
    role: role ?? this.role,
    joinedAt: joinedAt ?? this.joinedAt,
  );
  GroupRoundParticipant copyWithCompanion(
    GroupRoundParticipantsCompanion data,
  ) {
    return GroupRoundParticipant(
      id: data.id.present ? data.id.value : this.id,
      groupRoundId: data.groupRoundId.present
          ? data.groupRoundId.value
          : this.groupRoundId,
      userId: data.userId.present ? data.userId.value : this.userId,
      status: data.status.present ? data.status.value : this.status,
      role: data.role.present ? data.role.value : this.role,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRoundParticipant(')
          ..write('id: $id, ')
          ..write('groupRoundId: $groupRoundId, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, groupRoundId, userId, status, role, joinedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRoundParticipant &&
          other.id == this.id &&
          other.groupRoundId == this.groupRoundId &&
          other.userId == this.userId &&
          other.status == this.status &&
          other.role == this.role &&
          other.joinedAt == this.joinedAt);
}

class GroupRoundParticipantsCompanion
    extends UpdateCompanion<GroupRoundParticipant> {
  final Value<int> id;
  final Value<int> groupRoundId;
  final Value<String> userId;
  final Value<String> status;
  final Value<String> role;
  final Value<DateTime> joinedAt;
  const GroupRoundParticipantsCompanion({
    this.id = const Value.absent(),
    this.groupRoundId = const Value.absent(),
    this.userId = const Value.absent(),
    this.status = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
  });
  GroupRoundParticipantsCompanion.insert({
    this.id = const Value.absent(),
    required int groupRoundId,
    required String userId,
    this.status = const Value.absent(),
    this.role = const Value.absent(),
    this.joinedAt = const Value.absent(),
  }) : groupRoundId = Value(groupRoundId),
       userId = Value(userId);
  static Insertable<GroupRoundParticipant> custom({
    Expression<int>? id,
    Expression<int>? groupRoundId,
    Expression<String>? userId,
    Expression<String>? status,
    Expression<String>? role,
    Expression<DateTime>? joinedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupRoundId != null) 'group_round_id': groupRoundId,
      if (userId != null) 'user_id': userId,
      if (status != null) 'status': status,
      if (role != null) 'role': role,
      if (joinedAt != null) 'joined_at': joinedAt,
    });
  }

  GroupRoundParticipantsCompanion copyWith({
    Value<int>? id,
    Value<int>? groupRoundId,
    Value<String>? userId,
    Value<String>? status,
    Value<String>? role,
    Value<DateTime>? joinedAt,
  }) {
    return GroupRoundParticipantsCompanion(
      id: id ?? this.id,
      groupRoundId: groupRoundId ?? this.groupRoundId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (groupRoundId.present) {
      map['group_round_id'] = Variable<int>(groupRoundId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<DateTime>(joinedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupRoundParticipantsCompanion(')
          ..write('id: $id, ')
          ..write('groupRoundId: $groupRoundId, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('role: $role, ')
          ..write('joinedAt: $joinedAt')
          ..write(')'))
        .toString();
  }
}

class $DrillsTable extends Drills with TableInfo<$DrillsTable, Drill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrillsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('General'),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMinutesMeta = const VerificationMeta(
    'durationMinutes',
  );
  @override
  late final GeneratedColumn<int> durationMinutes = GeneratedColumn<int>(
    'duration_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('target'),
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    description,
    category,
    difficulty,
    durationMinutes,
    icon,
    isCustom,
    firestoreId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Drill> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('duration_minutes')) {
      context.handle(
        _durationMinutesMeta,
        durationMinutes.isAcceptableOrUnknown(
          data['duration_minutes']!,
          _durationMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_durationMinutesMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Drill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Drill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      durationMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_minutes'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
    );
  }

  @override
  $DrillsTable createAlias(String alias) {
    return $DrillsTable(attachedDatabase, alias);
  }
}

class Drill extends DataClass implements Insertable<Drill> {
  final int id;
  final String? userId;
  final String name;
  final String description;
  final String category;
  final String difficulty;
  final int durationMinutes;
  final String icon;
  final bool isCustom;
  final String? firestoreId;
  const Drill({
    required this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.durationMinutes,
    required this.icon,
    required this.isCustom,
    this.firestoreId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['name'] = Variable<String>(name);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['difficulty'] = Variable<String>(difficulty);
    map['duration_minutes'] = Variable<int>(durationMinutes);
    map['icon'] = Variable<String>(icon);
    map['is_custom'] = Variable<bool>(isCustom);
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    return map;
  }

  DrillsCompanion toCompanion(bool nullToAbsent) {
    return DrillsCompanion(
      id: Value(id),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      name: Value(name),
      description: Value(description),
      category: Value(category),
      difficulty: Value(difficulty),
      durationMinutes: Value(durationMinutes),
      icon: Value(icon),
      isCustom: Value(isCustom),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
    );
  }

  factory Drill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Drill(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String?>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      durationMinutes: serializer.fromJson<int>(json['durationMinutes']),
      icon: serializer.fromJson<String>(json['icon']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String?>(userId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'difficulty': serializer.toJson<String>(difficulty),
      'durationMinutes': serializer.toJson<int>(durationMinutes),
      'icon': serializer.toJson<String>(icon),
      'isCustom': serializer.toJson<bool>(isCustom),
      'firestoreId': serializer.toJson<String?>(firestoreId),
    };
  }

  Drill copyWith({
    int? id,
    Value<String?> userId = const Value.absent(),
    String? name,
    String? description,
    String? category,
    String? difficulty,
    int? durationMinutes,
    String? icon,
    bool? isCustom,
    Value<String?> firestoreId = const Value.absent(),
  }) => Drill(
    id: id ?? this.id,
    userId: userId.present ? userId.value : this.userId,
    name: name ?? this.name,
    description: description ?? this.description,
    category: category ?? this.category,
    difficulty: difficulty ?? this.difficulty,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    icon: icon ?? this.icon,
    isCustom: isCustom ?? this.isCustom,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
  );
  Drill copyWithCompanion(DrillsCompanion data) {
    return Drill(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      durationMinutes: data.durationMinutes.present
          ? data.durationMinutes.value
          : this.durationMinutes,
      icon: data.icon.present ? data.icon.value : this.icon,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Drill(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('icon: $icon, ')
          ..write('isCustom: $isCustom, ')
          ..write('firestoreId: $firestoreId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    description,
    category,
    difficulty,
    durationMinutes,
    icon,
    isCustom,
    firestoreId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Drill &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.difficulty == this.difficulty &&
          other.durationMinutes == this.durationMinutes &&
          other.icon == this.icon &&
          other.isCustom == this.isCustom &&
          other.firestoreId == this.firestoreId);
}

class DrillsCompanion extends UpdateCompanion<Drill> {
  final Value<int> id;
  final Value<String?> userId;
  final Value<String> name;
  final Value<String> description;
  final Value<String> category;
  final Value<String> difficulty;
  final Value<int> durationMinutes;
  final Value<String> icon;
  final Value<bool> isCustom;
  final Value<String?> firestoreId;
  const DrillsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.durationMinutes = const Value.absent(),
    this.icon = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.firestoreId = const Value.absent(),
  });
  DrillsCompanion.insert({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    required String name,
    required String description,
    this.category = const Value.absent(),
    required String difficulty,
    required int durationMinutes,
    this.icon = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.firestoreId = const Value.absent(),
  }) : name = Value(name),
       description = Value(description),
       difficulty = Value(difficulty),
       durationMinutes = Value(durationMinutes);
  static Insertable<Drill> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? difficulty,
    Expression<int>? durationMinutes,
    Expression<String>? icon,
    Expression<bool>? isCustom,
    Expression<String>? firestoreId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (difficulty != null) 'difficulty': difficulty,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (icon != null) 'icon': icon,
      if (isCustom != null) 'is_custom': isCustom,
      if (firestoreId != null) 'firestore_id': firestoreId,
    });
  }

  DrillsCompanion copyWith({
    Value<int>? id,
    Value<String?>? userId,
    Value<String>? name,
    Value<String>? description,
    Value<String>? category,
    Value<String>? difficulty,
    Value<int>? durationMinutes,
    Value<String>? icon,
    Value<bool>? isCustom,
    Value<String?>? firestoreId,
  }) {
    return DrillsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
      firestoreId: firestoreId ?? this.firestoreId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (durationMinutes.present) {
      map['duration_minutes'] = Variable<int>(durationMinutes.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrillsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('difficulty: $difficulty, ')
          ..write('durationMinutes: $durationMinutes, ')
          ..write('icon: $icon, ')
          ..write('isCustom: $isCustom, ')
          ..write('firestoreId: $firestoreId')
          ..write(')'))
        .toString();
  }
}

class $PracticeSessionsTable extends PracticeSessions
    with TableInfo<$PracticeSessionsTable, PracticeSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalBallsMeta = const VerificationMeta(
    'totalBalls',
  );
  @override
  late final GeneratedColumn<int> totalBalls = GeneratedColumn<int>(
    'total_balls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _sessionTypeMeta = const VerificationMeta(
    'sessionType',
  );
  @override
  late final GeneratedColumn<String> sessionType = GeneratedColumn<String>(
    'session_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('FREE'),
  );
  static const VerificationMeta _drillIdMeta = const VerificationMeta(
    'drillId',
  );
  @override
  late final GeneratedColumn<int> drillId = GeneratedColumn<int>(
    'drill_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES drills (id)',
    ),
  );
  static const VerificationMeta _targetDistanceMeta = const VerificationMeta(
    'targetDistance',
  );
  @override
  late final GeneratedColumn<int> targetDistance = GeneratedColumn<int>(
    'target_distance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    firestoreId,
    startTime,
    endTime,
    locationName,
    totalBalls,
    sessionType,
    drillId,
    targetDistance,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('total_balls')) {
      context.handle(
        _totalBallsMeta,
        totalBalls.isAcceptableOrUnknown(data['total_balls']!, _totalBallsMeta),
      );
    }
    if (data.containsKey('session_type')) {
      context.handle(
        _sessionTypeMeta,
        sessionType.isAcceptableOrUnknown(
          data['session_type']!,
          _sessionTypeMeta,
        ),
      );
    }
    if (data.containsKey('drill_id')) {
      context.handle(
        _drillIdMeta,
        drillId.isAcceptableOrUnknown(data['drill_id']!, _drillIdMeta),
      );
    }
    if (data.containsKey('target_distance')) {
      context.handle(
        _targetDistanceMeta,
        targetDistance.isAcceptableOrUnknown(
          data['target_distance']!,
          _targetDistanceMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      ),
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      totalBalls: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_balls'],
      )!,
      sessionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_type'],
      )!,
      drillId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drill_id'],
      ),
      targetDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_distance'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PracticeSessionsTable createAlias(String alias) {
    return $PracticeSessionsTable(attachedDatabase, alias);
  }
}

class PracticeSession extends DataClass implements Insertable<PracticeSession> {
  final int id;
  final String userId;
  final String? firestoreId;
  final DateTime startTime;
  final DateTime? endTime;
  final String? locationName;
  final int totalBalls;
  final String sessionType;
  final int? drillId;
  final int? targetDistance;
  final String? notes;
  final DateTime createdAt;
  const PracticeSession({
    required this.id,
    required this.userId,
    this.firestoreId,
    required this.startTime,
    this.endTime,
    this.locationName,
    required this.totalBalls,
    required this.sessionType,
    this.drillId,
    this.targetDistance,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<DateTime>(endTime);
    }
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    map['total_balls'] = Variable<int>(totalBalls);
    map['session_type'] = Variable<String>(sessionType);
    if (!nullToAbsent || drillId != null) {
      map['drill_id'] = Variable<int>(drillId);
    }
    if (!nullToAbsent || targetDistance != null) {
      map['target_distance'] = Variable<int>(targetDistance);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PracticeSessionsCompanion toCompanion(bool nullToAbsent) {
    return PracticeSessionsCompanion(
      id: Value(id),
      userId: Value(userId),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      startTime: Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      totalBalls: Value(totalBalls),
      sessionType: Value(sessionType),
      drillId: drillId == null && nullToAbsent
          ? const Value.absent()
          : Value(drillId),
      targetDistance: targetDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistance),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PracticeSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeSession(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime?>(json['endTime']),
      locationName: serializer.fromJson<String?>(json['locationName']),
      totalBalls: serializer.fromJson<int>(json['totalBalls']),
      sessionType: serializer.fromJson<String>(json['sessionType']),
      drillId: serializer.fromJson<int?>(json['drillId']),
      targetDistance: serializer.fromJson<int?>(json['targetDistance']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime?>(endTime),
      'locationName': serializer.toJson<String?>(locationName),
      'totalBalls': serializer.toJson<int>(totalBalls),
      'sessionType': serializer.toJson<String>(sessionType),
      'drillId': serializer.toJson<int?>(drillId),
      'targetDistance': serializer.toJson<int?>(targetDistance),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PracticeSession copyWith({
    int? id,
    String? userId,
    Value<String?> firestoreId = const Value.absent(),
    DateTime? startTime,
    Value<DateTime?> endTime = const Value.absent(),
    Value<String?> locationName = const Value.absent(),
    int? totalBalls,
    String? sessionType,
    Value<int?> drillId = const Value.absent(),
    Value<int?> targetDistance = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => PracticeSession(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    startTime: startTime ?? this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    locationName: locationName.present ? locationName.value : this.locationName,
    totalBalls: totalBalls ?? this.totalBalls,
    sessionType: sessionType ?? this.sessionType,
    drillId: drillId.present ? drillId.value : this.drillId,
    targetDistance: targetDistance.present
        ? targetDistance.value
        : this.targetDistance,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  PracticeSession copyWithCompanion(PracticeSessionsCompanion data) {
    return PracticeSession(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      totalBalls: data.totalBalls.present
          ? data.totalBalls.value
          : this.totalBalls,
      sessionType: data.sessionType.present
          ? data.sessionType.value
          : this.sessionType,
      drillId: data.drillId.present ? data.drillId.value : this.drillId,
      targetDistance: data.targetDistance.present
          ? data.targetDistance.value
          : this.targetDistance,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSession(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('locationName: $locationName, ')
          ..write('totalBalls: $totalBalls, ')
          ..write('sessionType: $sessionType, ')
          ..write('drillId: $drillId, ')
          ..write('targetDistance: $targetDistance, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    firestoreId,
    startTime,
    endTime,
    locationName,
    totalBalls,
    sessionType,
    drillId,
    targetDistance,
    notes,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeSession &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.firestoreId == this.firestoreId &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.locationName == this.locationName &&
          other.totalBalls == this.totalBalls &&
          other.sessionType == this.sessionType &&
          other.drillId == this.drillId &&
          other.targetDistance == this.targetDistance &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PracticeSessionsCompanion extends UpdateCompanion<PracticeSession> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String?> firestoreId;
  final Value<DateTime> startTime;
  final Value<DateTime?> endTime;
  final Value<String?> locationName;
  final Value<int> totalBalls;
  final Value<String> sessionType;
  final Value<int?> drillId;
  final Value<int?> targetDistance;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  const PracticeSessionsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.locationName = const Value.absent(),
    this.totalBalls = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.drillId = const Value.absent(),
    this.targetDistance = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PracticeSessionsCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    this.firestoreId = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.locationName = const Value.absent(),
    this.totalBalls = const Value.absent(),
    this.sessionType = const Value.absent(),
    this.drillId = const Value.absent(),
    this.targetDistance = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<PracticeSession> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? firestoreId,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<String>? locationName,
    Expression<int>? totalBalls,
    Expression<String>? sessionType,
    Expression<int>? drillId,
    Expression<int>? targetDistance,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (locationName != null) 'location_name': locationName,
      if (totalBalls != null) 'total_balls': totalBalls,
      if (sessionType != null) 'session_type': sessionType,
      if (drillId != null) 'drill_id': drillId,
      if (targetDistance != null) 'target_distance': targetDistance,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PracticeSessionsCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String?>? firestoreId,
    Value<DateTime>? startTime,
    Value<DateTime?>? endTime,
    Value<String?>? locationName,
    Value<int>? totalBalls,
    Value<String>? sessionType,
    Value<int?>? drillId,
    Value<int?>? targetDistance,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
  }) {
    return PracticeSessionsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firestoreId: firestoreId ?? this.firestoreId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      locationName: locationName ?? this.locationName,
      totalBalls: totalBalls ?? this.totalBalls,
      sessionType: sessionType ?? this.sessionType,
      drillId: drillId ?? this.drillId,
      targetDistance: targetDistance ?? this.targetDistance,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (totalBalls.present) {
      map['total_balls'] = Variable<int>(totalBalls.value);
    }
    if (sessionType.present) {
      map['session_type'] = Variable<String>(sessionType.value);
    }
    if (drillId.present) {
      map['drill_id'] = Variable<int>(drillId.value);
    }
    if (targetDistance.present) {
      map['target_distance'] = Variable<int>(targetDistance.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeSessionsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('locationName: $locationName, ')
          ..write('totalBalls: $totalBalls, ')
          ..write('sessionType: $sessionType, ')
          ..write('drillId: $drillId, ')
          ..write('targetDistance: $targetDistance, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PracticeShotsTable extends PracticeShots
    with TableInfo<$PracticeShotsTable, PracticeShot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PracticeShotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<int> sessionId = GeneratedColumn<int>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES practice_sessions (id)',
    ),
  );
  static const VerificationMeta _firestoreIdMeta = const VerificationMeta(
    'firestoreId',
  );
  @override
  late final GeneratedColumn<String> firestoreId = GeneratedColumn<String>(
    'firestore_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clubIdMeta = const VerificationMeta('clubId');
  @override
  late final GeneratedColumn<int> clubId = GeneratedColumn<int>(
    'club_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES clubs (id)',
    ),
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qualityMeta = const VerificationMeta(
    'quality',
  );
  @override
  late final GeneratedColumn<String> quality = GeneratedColumn<String>(
    'quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shotShapeMeta = const VerificationMeta(
    'shotShape',
  );
  @override
  late final GeneratedColumn<String> shotShape = GeneratedColumn<String>(
    'shot_shape',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ballFlightJsonMeta = const VerificationMeta(
    'ballFlightJson',
  );
  @override
  late final GeneratedColumn<String> ballFlightJson = GeneratedColumn<String>(
    'ball_flight_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoUrlMeta = const VerificationMeta(
    'videoUrl',
  );
  @override
  late final GeneratedColumn<String> videoUrl = GeneratedColumn<String>(
    'video_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _poseMetricsJsonMeta = const VerificationMeta(
    'poseMetricsJson',
  );
  @override
  late final GeneratedColumn<String> poseMetricsJson = GeneratedColumn<String>(
    'pose_metrics_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sessionId,
    firestoreId,
    clubId,
    distance,
    quality,
    shotShape,
    ballFlightJson,
    videoUrl,
    poseMetricsJson,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'practice_shots';
  @override
  VerificationContext validateIntegrity(
    Insertable<PracticeShot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('firestore_id')) {
      context.handle(
        _firestoreIdMeta,
        firestoreId.isAcceptableOrUnknown(
          data['firestore_id']!,
          _firestoreIdMeta,
        ),
      );
    }
    if (data.containsKey('club_id')) {
      context.handle(
        _clubIdMeta,
        clubId.isAcceptableOrUnknown(data['club_id']!, _clubIdMeta),
      );
    } else if (isInserting) {
      context.missing(_clubIdMeta);
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    if (data.containsKey('quality')) {
      context.handle(
        _qualityMeta,
        quality.isAcceptableOrUnknown(data['quality']!, _qualityMeta),
      );
    }
    if (data.containsKey('shot_shape')) {
      context.handle(
        _shotShapeMeta,
        shotShape.isAcceptableOrUnknown(data['shot_shape']!, _shotShapeMeta),
      );
    }
    if (data.containsKey('ball_flight_json')) {
      context.handle(
        _ballFlightJsonMeta,
        ballFlightJson.isAcceptableOrUnknown(
          data['ball_flight_json']!,
          _ballFlightJsonMeta,
        ),
      );
    }
    if (data.containsKey('video_url')) {
      context.handle(
        _videoUrlMeta,
        videoUrl.isAcceptableOrUnknown(data['video_url']!, _videoUrlMeta),
      );
    }
    if (data.containsKey('pose_metrics_json')) {
      context.handle(
        _poseMetricsJsonMeta,
        poseMetricsJson.isAcceptableOrUnknown(
          data['pose_metrics_json']!,
          _poseMetricsJsonMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PracticeShot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PracticeShot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_id'],
      )!,
      firestoreId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}firestore_id'],
      ),
      clubId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}club_id'],
      )!,
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
      quality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality'],
      ),
      shotShape: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shot_shape'],
      ),
      ballFlightJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ball_flight_json'],
      ),
      videoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_url'],
      ),
      poseMetricsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pose_metrics_json'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $PracticeShotsTable createAlias(String alias) {
    return $PracticeShotsTable(attachedDatabase, alias);
  }
}

class PracticeShot extends DataClass implements Insertable<PracticeShot> {
  final int id;
  final int sessionId;
  final String? firestoreId;
  final int clubId;
  final double? distance;
  final String? quality;
  final String? shotShape;
  final String? ballFlightJson;
  final String? videoUrl;
  final String? poseMetricsJson;
  final DateTime timestamp;
  const PracticeShot({
    required this.id,
    required this.sessionId,
    this.firestoreId,
    required this.clubId,
    this.distance,
    this.quality,
    this.shotShape,
    this.ballFlightJson,
    this.videoUrl,
    this.poseMetricsJson,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['session_id'] = Variable<int>(sessionId);
    if (!nullToAbsent || firestoreId != null) {
      map['firestore_id'] = Variable<String>(firestoreId);
    }
    map['club_id'] = Variable<int>(clubId);
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || quality != null) {
      map['quality'] = Variable<String>(quality);
    }
    if (!nullToAbsent || shotShape != null) {
      map['shot_shape'] = Variable<String>(shotShape);
    }
    if (!nullToAbsent || ballFlightJson != null) {
      map['ball_flight_json'] = Variable<String>(ballFlightJson);
    }
    if (!nullToAbsent || videoUrl != null) {
      map['video_url'] = Variable<String>(videoUrl);
    }
    if (!nullToAbsent || poseMetricsJson != null) {
      map['pose_metrics_json'] = Variable<String>(poseMetricsJson);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  PracticeShotsCompanion toCompanion(bool nullToAbsent) {
    return PracticeShotsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      firestoreId: firestoreId == null && nullToAbsent
          ? const Value.absent()
          : Value(firestoreId),
      clubId: Value(clubId),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      quality: quality == null && nullToAbsent
          ? const Value.absent()
          : Value(quality),
      shotShape: shotShape == null && nullToAbsent
          ? const Value.absent()
          : Value(shotShape),
      ballFlightJson: ballFlightJson == null && nullToAbsent
          ? const Value.absent()
          : Value(ballFlightJson),
      videoUrl: videoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(videoUrl),
      poseMetricsJson: poseMetricsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(poseMetricsJson),
      timestamp: Value(timestamp),
    );
  }

  factory PracticeShot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PracticeShot(
      id: serializer.fromJson<int>(json['id']),
      sessionId: serializer.fromJson<int>(json['sessionId']),
      firestoreId: serializer.fromJson<String?>(json['firestoreId']),
      clubId: serializer.fromJson<int>(json['clubId']),
      distance: serializer.fromJson<double?>(json['distance']),
      quality: serializer.fromJson<String?>(json['quality']),
      shotShape: serializer.fromJson<String?>(json['shotShape']),
      ballFlightJson: serializer.fromJson<String?>(json['ballFlightJson']),
      videoUrl: serializer.fromJson<String?>(json['videoUrl']),
      poseMetricsJson: serializer.fromJson<String?>(json['poseMetricsJson']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'sessionId': serializer.toJson<int>(sessionId),
      'firestoreId': serializer.toJson<String?>(firestoreId),
      'clubId': serializer.toJson<int>(clubId),
      'distance': serializer.toJson<double?>(distance),
      'quality': serializer.toJson<String?>(quality),
      'shotShape': serializer.toJson<String?>(shotShape),
      'ballFlightJson': serializer.toJson<String?>(ballFlightJson),
      'videoUrl': serializer.toJson<String?>(videoUrl),
      'poseMetricsJson': serializer.toJson<String?>(poseMetricsJson),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  PracticeShot copyWith({
    int? id,
    int? sessionId,
    Value<String?> firestoreId = const Value.absent(),
    int? clubId,
    Value<double?> distance = const Value.absent(),
    Value<String?> quality = const Value.absent(),
    Value<String?> shotShape = const Value.absent(),
    Value<String?> ballFlightJson = const Value.absent(),
    Value<String?> videoUrl = const Value.absent(),
    Value<String?> poseMetricsJson = const Value.absent(),
    DateTime? timestamp,
  }) => PracticeShot(
    id: id ?? this.id,
    sessionId: sessionId ?? this.sessionId,
    firestoreId: firestoreId.present ? firestoreId.value : this.firestoreId,
    clubId: clubId ?? this.clubId,
    distance: distance.present ? distance.value : this.distance,
    quality: quality.present ? quality.value : this.quality,
    shotShape: shotShape.present ? shotShape.value : this.shotShape,
    ballFlightJson: ballFlightJson.present
        ? ballFlightJson.value
        : this.ballFlightJson,
    videoUrl: videoUrl.present ? videoUrl.value : this.videoUrl,
    poseMetricsJson: poseMetricsJson.present
        ? poseMetricsJson.value
        : this.poseMetricsJson,
    timestamp: timestamp ?? this.timestamp,
  );
  PracticeShot copyWithCompanion(PracticeShotsCompanion data) {
    return PracticeShot(
      id: data.id.present ? data.id.value : this.id,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      firestoreId: data.firestoreId.present
          ? data.firestoreId.value
          : this.firestoreId,
      clubId: data.clubId.present ? data.clubId.value : this.clubId,
      distance: data.distance.present ? data.distance.value : this.distance,
      quality: data.quality.present ? data.quality.value : this.quality,
      shotShape: data.shotShape.present ? data.shotShape.value : this.shotShape,
      ballFlightJson: data.ballFlightJson.present
          ? data.ballFlightJson.value
          : this.ballFlightJson,
      videoUrl: data.videoUrl.present ? data.videoUrl.value : this.videoUrl,
      poseMetricsJson: data.poseMetricsJson.present
          ? data.poseMetricsJson.value
          : this.poseMetricsJson,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PracticeShot(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('clubId: $clubId, ')
          ..write('distance: $distance, ')
          ..write('quality: $quality, ')
          ..write('shotShape: $shotShape, ')
          ..write('ballFlightJson: $ballFlightJson, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('poseMetricsJson: $poseMetricsJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sessionId,
    firestoreId,
    clubId,
    distance,
    quality,
    shotShape,
    ballFlightJson,
    videoUrl,
    poseMetricsJson,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PracticeShot &&
          other.id == this.id &&
          other.sessionId == this.sessionId &&
          other.firestoreId == this.firestoreId &&
          other.clubId == this.clubId &&
          other.distance == this.distance &&
          other.quality == this.quality &&
          other.shotShape == this.shotShape &&
          other.ballFlightJson == this.ballFlightJson &&
          other.videoUrl == this.videoUrl &&
          other.poseMetricsJson == this.poseMetricsJson &&
          other.timestamp == this.timestamp);
}

class PracticeShotsCompanion extends UpdateCompanion<PracticeShot> {
  final Value<int> id;
  final Value<int> sessionId;
  final Value<String?> firestoreId;
  final Value<int> clubId;
  final Value<double?> distance;
  final Value<String?> quality;
  final Value<String?> shotShape;
  final Value<String?> ballFlightJson;
  final Value<String?> videoUrl;
  final Value<String?> poseMetricsJson;
  final Value<DateTime> timestamp;
  const PracticeShotsCompanion({
    this.id = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.firestoreId = const Value.absent(),
    this.clubId = const Value.absent(),
    this.distance = const Value.absent(),
    this.quality = const Value.absent(),
    this.shotShape = const Value.absent(),
    this.ballFlightJson = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.poseMetricsJson = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  PracticeShotsCompanion.insert({
    this.id = const Value.absent(),
    required int sessionId,
    this.firestoreId = const Value.absent(),
    required int clubId,
    this.distance = const Value.absent(),
    this.quality = const Value.absent(),
    this.shotShape = const Value.absent(),
    this.ballFlightJson = const Value.absent(),
    this.videoUrl = const Value.absent(),
    this.poseMetricsJson = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : sessionId = Value(sessionId),
       clubId = Value(clubId);
  static Insertable<PracticeShot> custom({
    Expression<int>? id,
    Expression<int>? sessionId,
    Expression<String>? firestoreId,
    Expression<int>? clubId,
    Expression<double>? distance,
    Expression<String>? quality,
    Expression<String>? shotShape,
    Expression<String>? ballFlightJson,
    Expression<String>? videoUrl,
    Expression<String>? poseMetricsJson,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sessionId != null) 'session_id': sessionId,
      if (firestoreId != null) 'firestore_id': firestoreId,
      if (clubId != null) 'club_id': clubId,
      if (distance != null) 'distance': distance,
      if (quality != null) 'quality': quality,
      if (shotShape != null) 'shot_shape': shotShape,
      if (ballFlightJson != null) 'ball_flight_json': ballFlightJson,
      if (videoUrl != null) 'video_url': videoUrl,
      if (poseMetricsJson != null) 'pose_metrics_json': poseMetricsJson,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  PracticeShotsCompanion copyWith({
    Value<int>? id,
    Value<int>? sessionId,
    Value<String?>? firestoreId,
    Value<int>? clubId,
    Value<double?>? distance,
    Value<String?>? quality,
    Value<String?>? shotShape,
    Value<String?>? ballFlightJson,
    Value<String?>? videoUrl,
    Value<String?>? poseMetricsJson,
    Value<DateTime>? timestamp,
  }) {
    return PracticeShotsCompanion(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      firestoreId: firestoreId ?? this.firestoreId,
      clubId: clubId ?? this.clubId,
      distance: distance ?? this.distance,
      quality: quality ?? this.quality,
      shotShape: shotShape ?? this.shotShape,
      ballFlightJson: ballFlightJson ?? this.ballFlightJson,
      videoUrl: videoUrl ?? this.videoUrl,
      poseMetricsJson: poseMetricsJson ?? this.poseMetricsJson,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<int>(sessionId.value);
    }
    if (firestoreId.present) {
      map['firestore_id'] = Variable<String>(firestoreId.value);
    }
    if (clubId.present) {
      map['club_id'] = Variable<int>(clubId.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (quality.present) {
      map['quality'] = Variable<String>(quality.value);
    }
    if (shotShape.present) {
      map['shot_shape'] = Variable<String>(shotShape.value);
    }
    if (ballFlightJson.present) {
      map['ball_flight_json'] = Variable<String>(ballFlightJson.value);
    }
    if (videoUrl.present) {
      map['video_url'] = Variable<String>(videoUrl.value);
    }
    if (poseMetricsJson.present) {
      map['pose_metrics_json'] = Variable<String>(poseMetricsJson.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PracticeShotsCompanion(')
          ..write('id: $id, ')
          ..write('sessionId: $sessionId, ')
          ..write('firestoreId: $firestoreId, ')
          ..write('clubId: $clubId, ')
          ..write('distance: $distance, ')
          ..write('quality: $quality, ')
          ..write('shotShape: $shotShape, ')
          ..write('ballFlightJson: $ballFlightJson, ')
          ..write('videoUrl: $videoUrl, ')
          ..write('poseMetricsJson: $poseMetricsJson, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $DrillStepsTable extends DrillSteps
    with TableInfo<$DrillStepsTable, DrillStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DrillStepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _drillIdMeta = const VerificationMeta(
    'drillId',
  );
  @override
  late final GeneratedColumn<int> drillId = GeneratedColumn<int>(
    'drill_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES drills (id)',
    ),
  );
  static const VerificationMeta _stepOrderMeta = const VerificationMeta(
    'stepOrder',
  );
  @override
  late final GeneratedColumn<int> stepOrder = GeneratedColumn<int>(
    'step_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _instructionMeta = const VerificationMeta(
    'instruction',
  );
  @override
  late final GeneratedColumn<String> instruction = GeneratedColumn<String>(
    'instruction',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetDistanceMeta = const VerificationMeta(
    'targetDistance',
  );
  @override
  late final GeneratedColumn<int> targetDistance = GeneratedColumn<int>(
    'target_distance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ballsRequiredMeta = const VerificationMeta(
    'ballsRequired',
  );
  @override
  late final GeneratedColumn<int> ballsRequired = GeneratedColumn<int>(
    'balls_required',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _clubTypeMeta = const VerificationMeta(
    'clubType',
  );
  @override
  late final GeneratedColumn<String> clubType = GeneratedColumn<String>(
    'club_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    drillId,
    stepOrder,
    instruction,
    targetDistance,
    ballsRequired,
    clubType,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'drill_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<DrillStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('drill_id')) {
      context.handle(
        _drillIdMeta,
        drillId.isAcceptableOrUnknown(data['drill_id']!, _drillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_drillIdMeta);
    }
    if (data.containsKey('step_order')) {
      context.handle(
        _stepOrderMeta,
        stepOrder.isAcceptableOrUnknown(data['step_order']!, _stepOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_stepOrderMeta);
    }
    if (data.containsKey('instruction')) {
      context.handle(
        _instructionMeta,
        instruction.isAcceptableOrUnknown(
          data['instruction']!,
          _instructionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_instructionMeta);
    }
    if (data.containsKey('target_distance')) {
      context.handle(
        _targetDistanceMeta,
        targetDistance.isAcceptableOrUnknown(
          data['target_distance']!,
          _targetDistanceMeta,
        ),
      );
    }
    if (data.containsKey('balls_required')) {
      context.handle(
        _ballsRequiredMeta,
        ballsRequired.isAcceptableOrUnknown(
          data['balls_required']!,
          _ballsRequiredMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ballsRequiredMeta);
    }
    if (data.containsKey('club_type')) {
      context.handle(
        _clubTypeMeta,
        clubType.isAcceptableOrUnknown(data['club_type']!, _clubTypeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DrillStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DrillStep(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      drillId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}drill_id'],
      )!,
      stepOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_order'],
      )!,
      instruction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instruction'],
      )!,
      targetDistance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_distance'],
      ),
      ballsRequired: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balls_required'],
      )!,
      clubType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}club_type'],
      ),
    );
  }

  @override
  $DrillStepsTable createAlias(String alias) {
    return $DrillStepsTable(attachedDatabase, alias);
  }
}

class DrillStep extends DataClass implements Insertable<DrillStep> {
  final int id;
  final int drillId;
  final int stepOrder;
  final String instruction;
  final int? targetDistance;
  final int ballsRequired;
  final String? clubType;
  const DrillStep({
    required this.id,
    required this.drillId,
    required this.stepOrder,
    required this.instruction,
    this.targetDistance,
    required this.ballsRequired,
    this.clubType,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['drill_id'] = Variable<int>(drillId);
    map['step_order'] = Variable<int>(stepOrder);
    map['instruction'] = Variable<String>(instruction);
    if (!nullToAbsent || targetDistance != null) {
      map['target_distance'] = Variable<int>(targetDistance);
    }
    map['balls_required'] = Variable<int>(ballsRequired);
    if (!nullToAbsent || clubType != null) {
      map['club_type'] = Variable<String>(clubType);
    }
    return map;
  }

  DrillStepsCompanion toCompanion(bool nullToAbsent) {
    return DrillStepsCompanion(
      id: Value(id),
      drillId: Value(drillId),
      stepOrder: Value(stepOrder),
      instruction: Value(instruction),
      targetDistance: targetDistance == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDistance),
      ballsRequired: Value(ballsRequired),
      clubType: clubType == null && nullToAbsent
          ? const Value.absent()
          : Value(clubType),
    );
  }

  factory DrillStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DrillStep(
      id: serializer.fromJson<int>(json['id']),
      drillId: serializer.fromJson<int>(json['drillId']),
      stepOrder: serializer.fromJson<int>(json['stepOrder']),
      instruction: serializer.fromJson<String>(json['instruction']),
      targetDistance: serializer.fromJson<int?>(json['targetDistance']),
      ballsRequired: serializer.fromJson<int>(json['ballsRequired']),
      clubType: serializer.fromJson<String?>(json['clubType']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'drillId': serializer.toJson<int>(drillId),
      'stepOrder': serializer.toJson<int>(stepOrder),
      'instruction': serializer.toJson<String>(instruction),
      'targetDistance': serializer.toJson<int?>(targetDistance),
      'ballsRequired': serializer.toJson<int>(ballsRequired),
      'clubType': serializer.toJson<String?>(clubType),
    };
  }

  DrillStep copyWith({
    int? id,
    int? drillId,
    int? stepOrder,
    String? instruction,
    Value<int?> targetDistance = const Value.absent(),
    int? ballsRequired,
    Value<String?> clubType = const Value.absent(),
  }) => DrillStep(
    id: id ?? this.id,
    drillId: drillId ?? this.drillId,
    stepOrder: stepOrder ?? this.stepOrder,
    instruction: instruction ?? this.instruction,
    targetDistance: targetDistance.present
        ? targetDistance.value
        : this.targetDistance,
    ballsRequired: ballsRequired ?? this.ballsRequired,
    clubType: clubType.present ? clubType.value : this.clubType,
  );
  DrillStep copyWithCompanion(DrillStepsCompanion data) {
    return DrillStep(
      id: data.id.present ? data.id.value : this.id,
      drillId: data.drillId.present ? data.drillId.value : this.drillId,
      stepOrder: data.stepOrder.present ? data.stepOrder.value : this.stepOrder,
      instruction: data.instruction.present
          ? data.instruction.value
          : this.instruction,
      targetDistance: data.targetDistance.present
          ? data.targetDistance.value
          : this.targetDistance,
      ballsRequired: data.ballsRequired.present
          ? data.ballsRequired.value
          : this.ballsRequired,
      clubType: data.clubType.present ? data.clubType.value : this.clubType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DrillStep(')
          ..write('id: $id, ')
          ..write('drillId: $drillId, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('instruction: $instruction, ')
          ..write('targetDistance: $targetDistance, ')
          ..write('ballsRequired: $ballsRequired, ')
          ..write('clubType: $clubType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    drillId,
    stepOrder,
    instruction,
    targetDistance,
    ballsRequired,
    clubType,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrillStep &&
          other.id == this.id &&
          other.drillId == this.drillId &&
          other.stepOrder == this.stepOrder &&
          other.instruction == this.instruction &&
          other.targetDistance == this.targetDistance &&
          other.ballsRequired == this.ballsRequired &&
          other.clubType == this.clubType);
}

class DrillStepsCompanion extends UpdateCompanion<DrillStep> {
  final Value<int> id;
  final Value<int> drillId;
  final Value<int> stepOrder;
  final Value<String> instruction;
  final Value<int?> targetDistance;
  final Value<int> ballsRequired;
  final Value<String?> clubType;
  const DrillStepsCompanion({
    this.id = const Value.absent(),
    this.drillId = const Value.absent(),
    this.stepOrder = const Value.absent(),
    this.instruction = const Value.absent(),
    this.targetDistance = const Value.absent(),
    this.ballsRequired = const Value.absent(),
    this.clubType = const Value.absent(),
  });
  DrillStepsCompanion.insert({
    this.id = const Value.absent(),
    required int drillId,
    required int stepOrder,
    required String instruction,
    this.targetDistance = const Value.absent(),
    required int ballsRequired,
    this.clubType = const Value.absent(),
  }) : drillId = Value(drillId),
       stepOrder = Value(stepOrder),
       instruction = Value(instruction),
       ballsRequired = Value(ballsRequired);
  static Insertable<DrillStep> custom({
    Expression<int>? id,
    Expression<int>? drillId,
    Expression<int>? stepOrder,
    Expression<String>? instruction,
    Expression<int>? targetDistance,
    Expression<int>? ballsRequired,
    Expression<String>? clubType,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (drillId != null) 'drill_id': drillId,
      if (stepOrder != null) 'step_order': stepOrder,
      if (instruction != null) 'instruction': instruction,
      if (targetDistance != null) 'target_distance': targetDistance,
      if (ballsRequired != null) 'balls_required': ballsRequired,
      if (clubType != null) 'club_type': clubType,
    });
  }

  DrillStepsCompanion copyWith({
    Value<int>? id,
    Value<int>? drillId,
    Value<int>? stepOrder,
    Value<String>? instruction,
    Value<int?>? targetDistance,
    Value<int>? ballsRequired,
    Value<String?>? clubType,
  }) {
    return DrillStepsCompanion(
      id: id ?? this.id,
      drillId: drillId ?? this.drillId,
      stepOrder: stepOrder ?? this.stepOrder,
      instruction: instruction ?? this.instruction,
      targetDistance: targetDistance ?? this.targetDistance,
      ballsRequired: ballsRequired ?? this.ballsRequired,
      clubType: clubType ?? this.clubType,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (drillId.present) {
      map['drill_id'] = Variable<int>(drillId.value);
    }
    if (stepOrder.present) {
      map['step_order'] = Variable<int>(stepOrder.value);
    }
    if (instruction.present) {
      map['instruction'] = Variable<String>(instruction.value);
    }
    if (targetDistance.present) {
      map['target_distance'] = Variable<int>(targetDistance.value);
    }
    if (ballsRequired.present) {
      map['balls_required'] = Variable<int>(ballsRequired.value);
    }
    if (clubType.present) {
      map['club_type'] = Variable<String>(clubType.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DrillStepsCompanion(')
          ..write('id: $id, ')
          ..write('drillId: $drillId, ')
          ..write('stepOrder: $stepOrder, ')
          ..write('instruction: $instruction, ')
          ..write('targetDistance: $targetDistance, ')
          ..write('ballsRequired: $ballsRequired, ')
          ..write('clubType: $clubType')
          ..write(')'))
        .toString();
  }
}

class $ProvidersTable extends Providers
    with TableInfo<$ProvidersTable, Provider> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _whatsappMeta = const VerificationMeta(
    'whatsapp',
  );
  @override
  late final GeneratedColumn<String> whatsapp = GeneratedColumn<String>(
    'whatsapp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _experienceMeta = const VerificationMeta(
    'experience',
  );
  @override
  late final GeneratedColumn<int> experience = GeneratedColumn<int>(
    'experience',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _coursesJsonMeta = const VerificationMeta(
    'coursesJson',
  );
  @override
  late final GeneratedColumn<String> coursesJson = GeneratedColumn<String>(
    'courses_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _specializationsJsonMeta =
      const VerificationMeta('specializationsJson');
  @override
  late final GeneratedColumn<String> specializationsJson =
      GeneratedColumn<String>(
        'specializations_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _availabilityJsonMeta = const VerificationMeta(
    'availabilityJson',
  );
  @override
  late final GeneratedColumn<String> availabilityJson = GeneratedColumn<String>(
    'availability_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _priceMeta = const VerificationMeta('price');
  @override
  late final GeneratedColumn<double> price = GeneratedColumn<double>(
    'price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalReviewsMeta = const VerificationMeta(
    'totalReviews',
  );
  @override
  late final GeneratedColumn<int> totalReviews = GeneratedColumn<int>(
    'total_reviews',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBookingsMeta = const VerificationMeta(
    'totalBookings',
  );
  @override
  late final GeneratedColumn<int> totalBookings = GeneratedColumn<int>(
    'total_bookings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalCallsMeta = const VerificationMeta(
    'totalCalls',
  );
  @override
  late final GeneratedColumn<int> totalCalls = GeneratedColumn<int>(
    'total_calls',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isAvailableMeta = const VerificationMeta(
    'isAvailable',
  );
  @override
  late final GeneratedColumn<bool> isAvailable = GeneratedColumn<bool>(
    'is_available',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_available" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _profileCompleteMeta = const VerificationMeta(
    'profileComplete',
  );
  @override
  late final GeneratedColumn<bool> profileComplete = GeneratedColumn<bool>(
    'profile_complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("profile_complete" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _certificationUrlMeta = const VerificationMeta(
    'certificationUrl',
  );
  @override
  late final GeneratedColumn<String> certificationUrl = GeneratedColumn<String>(
    'certification_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _personalityTypeMeta = const VerificationMeta(
    'personalityType',
  );
  @override
  late final GeneratedColumn<String> personalityType = GeneratedColumn<String>(
    'personality_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coachingLocationMeta = const VerificationMeta(
    'coachingLocation',
  );
  @override
  late final GeneratedColumn<String> coachingLocation = GeneratedColumn<String>(
    'coaching_location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coachingStylesJsonMeta =
      const VerificationMeta('coachingStylesJson');
  @override
  late final GeneratedColumn<String> coachingStylesJson =
      GeneratedColumn<String>(
        'coaching_styles_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sessionTypesJsonMeta = const VerificationMeta(
    'sessionTypesJson',
  );
  @override
  late final GeneratedColumn<String> sessionTypesJson = GeneratedColumn<String>(
    'session_types_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasCertificationMeta = const VerificationMeta(
    'hasCertification',
  );
  @override
  late final GeneratedColumn<bool> hasCertification = GeneratedColumn<bool>(
    'has_certification',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_certification" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _certificationNameMeta = const VerificationMeta(
    'certificationName',
  );
  @override
  late final GeneratedColumn<String> certificationName =
      GeneratedColumn<String>(
        'certification_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _viewsMeta = const VerificationMeta('views');
  @override
  late final GeneratedColumn<int> views = GeneratedColumn<int>(
    'views',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _streakMeta = const VerificationMeta('streak');
  @override
  late final GeneratedColumn<int> streak = GeneratedColumn<int>(
    'streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    role,
    name,
    phone,
    whatsapp,
    experience,
    coursesJson,
    specializationsJson,
    availabilityJson,
    price,
    rating,
    totalReviews,
    totalBookings,
    totalCalls,
    isAvailable,
    profileComplete,
    certificationUrl,
    bio,
    personalityType,
    coachingLocation,
    coachingStylesJson,
    sessionTypesJson,
    hasCertification,
    certificationName,
    views,
    streak,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Provider> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('whatsapp')) {
      context.handle(
        _whatsappMeta,
        whatsapp.isAcceptableOrUnknown(data['whatsapp']!, _whatsappMeta),
      );
    }
    if (data.containsKey('experience')) {
      context.handle(
        _experienceMeta,
        experience.isAcceptableOrUnknown(data['experience']!, _experienceMeta),
      );
    }
    if (data.containsKey('courses_json')) {
      context.handle(
        _coursesJsonMeta,
        coursesJson.isAcceptableOrUnknown(
          data['courses_json']!,
          _coursesJsonMeta,
        ),
      );
    }
    if (data.containsKey('specializations_json')) {
      context.handle(
        _specializationsJsonMeta,
        specializationsJson.isAcceptableOrUnknown(
          data['specializations_json']!,
          _specializationsJsonMeta,
        ),
      );
    }
    if (data.containsKey('availability_json')) {
      context.handle(
        _availabilityJsonMeta,
        availabilityJson.isAcceptableOrUnknown(
          data['availability_json']!,
          _availabilityJsonMeta,
        ),
      );
    }
    if (data.containsKey('price')) {
      context.handle(
        _priceMeta,
        price.isAcceptableOrUnknown(data['price']!, _priceMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('total_reviews')) {
      context.handle(
        _totalReviewsMeta,
        totalReviews.isAcceptableOrUnknown(
          data['total_reviews']!,
          _totalReviewsMeta,
        ),
      );
    }
    if (data.containsKey('total_bookings')) {
      context.handle(
        _totalBookingsMeta,
        totalBookings.isAcceptableOrUnknown(
          data['total_bookings']!,
          _totalBookingsMeta,
        ),
      );
    }
    if (data.containsKey('total_calls')) {
      context.handle(
        _totalCallsMeta,
        totalCalls.isAcceptableOrUnknown(data['total_calls']!, _totalCallsMeta),
      );
    }
    if (data.containsKey('is_available')) {
      context.handle(
        _isAvailableMeta,
        isAvailable.isAcceptableOrUnknown(
          data['is_available']!,
          _isAvailableMeta,
        ),
      );
    }
    if (data.containsKey('profile_complete')) {
      context.handle(
        _profileCompleteMeta,
        profileComplete.isAcceptableOrUnknown(
          data['profile_complete']!,
          _profileCompleteMeta,
        ),
      );
    }
    if (data.containsKey('certification_url')) {
      context.handle(
        _certificationUrlMeta,
        certificationUrl.isAcceptableOrUnknown(
          data['certification_url']!,
          _certificationUrlMeta,
        ),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('personality_type')) {
      context.handle(
        _personalityTypeMeta,
        personalityType.isAcceptableOrUnknown(
          data['personality_type']!,
          _personalityTypeMeta,
        ),
      );
    }
    if (data.containsKey('coaching_location')) {
      context.handle(
        _coachingLocationMeta,
        coachingLocation.isAcceptableOrUnknown(
          data['coaching_location']!,
          _coachingLocationMeta,
        ),
      );
    }
    if (data.containsKey('coaching_styles_json')) {
      context.handle(
        _coachingStylesJsonMeta,
        coachingStylesJson.isAcceptableOrUnknown(
          data['coaching_styles_json']!,
          _coachingStylesJsonMeta,
        ),
      );
    }
    if (data.containsKey('session_types_json')) {
      context.handle(
        _sessionTypesJsonMeta,
        sessionTypesJson.isAcceptableOrUnknown(
          data['session_types_json']!,
          _sessionTypesJsonMeta,
        ),
      );
    }
    if (data.containsKey('has_certification')) {
      context.handle(
        _hasCertificationMeta,
        hasCertification.isAcceptableOrUnknown(
          data['has_certification']!,
          _hasCertificationMeta,
        ),
      );
    }
    if (data.containsKey('certification_name')) {
      context.handle(
        _certificationNameMeta,
        certificationName.isAcceptableOrUnknown(
          data['certification_name']!,
          _certificationNameMeta,
        ),
      );
    }
    if (data.containsKey('views')) {
      context.handle(
        _viewsMeta,
        views.isAcceptableOrUnknown(data['views']!, _viewsMeta),
      );
    }
    if (data.containsKey('streak')) {
      context.handle(
        _streakMeta,
        streak.isAcceptableOrUnknown(data['streak']!, _streakMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Provider map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Provider(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      whatsapp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}whatsapp'],
      ),
      experience: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}experience'],
      )!,
      coursesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}courses_json'],
      )!,
      specializationsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}specializations_json'],
      ),
      availabilityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability_json'],
      )!,
      price: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}price'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      )!,
      totalReviews: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_reviews'],
      )!,
      totalBookings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bookings'],
      )!,
      totalCalls: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_calls'],
      )!,
      isAvailable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_available'],
      )!,
      profileComplete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}profile_complete'],
      )!,
      certificationUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certification_url'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      personalityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}personality_type'],
      ),
      coachingLocation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coaching_location'],
      ),
      coachingStylesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}coaching_styles_json'],
      ),
      sessionTypesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_types_json'],
      ),
      hasCertification: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_certification'],
      )!,
      certificationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}certification_name'],
      ),
      views: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}views'],
      )!,
      streak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProvidersTable createAlias(String alias) {
    return $ProvidersTable(attachedDatabase, alias);
  }
}

class Provider extends DataClass implements Insertable<Provider> {
  final int id;
  final String userId;
  final String role;
  final String name;
  final String phone;
  final String? whatsapp;
  final int experience;
  final String coursesJson;
  final String? specializationsJson;
  final String availabilityJson;
  final double? price;
  final double rating;
  final int totalReviews;
  final int totalBookings;
  final int totalCalls;
  final bool isAvailable;
  final bool profileComplete;
  final String? certificationUrl;
  final String? bio;
  final String? personalityType;
  final String? coachingLocation;
  final String? coachingStylesJson;
  final String? sessionTypesJson;
  final bool hasCertification;
  final String? certificationName;
  final int views;
  final int streak;
  final DateTime createdAt;
  const Provider({
    required this.id,
    required this.userId,
    required this.role,
    required this.name,
    required this.phone,
    this.whatsapp,
    required this.experience,
    required this.coursesJson,
    this.specializationsJson,
    required this.availabilityJson,
    this.price,
    required this.rating,
    required this.totalReviews,
    required this.totalBookings,
    required this.totalCalls,
    required this.isAvailable,
    required this.profileComplete,
    this.certificationUrl,
    this.bio,
    this.personalityType,
    this.coachingLocation,
    this.coachingStylesJson,
    this.sessionTypesJson,
    required this.hasCertification,
    this.certificationName,
    required this.views,
    required this.streak,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['user_id'] = Variable<String>(userId);
    map['role'] = Variable<String>(role);
    map['name'] = Variable<String>(name);
    map['phone'] = Variable<String>(phone);
    if (!nullToAbsent || whatsapp != null) {
      map['whatsapp'] = Variable<String>(whatsapp);
    }
    map['experience'] = Variable<int>(experience);
    map['courses_json'] = Variable<String>(coursesJson);
    if (!nullToAbsent || specializationsJson != null) {
      map['specializations_json'] = Variable<String>(specializationsJson);
    }
    map['availability_json'] = Variable<String>(availabilityJson);
    if (!nullToAbsent || price != null) {
      map['price'] = Variable<double>(price);
    }
    map['rating'] = Variable<double>(rating);
    map['total_reviews'] = Variable<int>(totalReviews);
    map['total_bookings'] = Variable<int>(totalBookings);
    map['total_calls'] = Variable<int>(totalCalls);
    map['is_available'] = Variable<bool>(isAvailable);
    map['profile_complete'] = Variable<bool>(profileComplete);
    if (!nullToAbsent || certificationUrl != null) {
      map['certification_url'] = Variable<String>(certificationUrl);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || personalityType != null) {
      map['personality_type'] = Variable<String>(personalityType);
    }
    if (!nullToAbsent || coachingLocation != null) {
      map['coaching_location'] = Variable<String>(coachingLocation);
    }
    if (!nullToAbsent || coachingStylesJson != null) {
      map['coaching_styles_json'] = Variable<String>(coachingStylesJson);
    }
    if (!nullToAbsent || sessionTypesJson != null) {
      map['session_types_json'] = Variable<String>(sessionTypesJson);
    }
    map['has_certification'] = Variable<bool>(hasCertification);
    if (!nullToAbsent || certificationName != null) {
      map['certification_name'] = Variable<String>(certificationName);
    }
    map['views'] = Variable<int>(views);
    map['streak'] = Variable<int>(streak);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProvidersCompanion toCompanion(bool nullToAbsent) {
    return ProvidersCompanion(
      id: Value(id),
      userId: Value(userId),
      role: Value(role),
      name: Value(name),
      phone: Value(phone),
      whatsapp: whatsapp == null && nullToAbsent
          ? const Value.absent()
          : Value(whatsapp),
      experience: Value(experience),
      coursesJson: Value(coursesJson),
      specializationsJson: specializationsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(specializationsJson),
      availabilityJson: Value(availabilityJson),
      price: price == null && nullToAbsent
          ? const Value.absent()
          : Value(price),
      rating: Value(rating),
      totalReviews: Value(totalReviews),
      totalBookings: Value(totalBookings),
      totalCalls: Value(totalCalls),
      isAvailable: Value(isAvailable),
      profileComplete: Value(profileComplete),
      certificationUrl: certificationUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(certificationUrl),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      personalityType: personalityType == null && nullToAbsent
          ? const Value.absent()
          : Value(personalityType),
      coachingLocation: coachingLocation == null && nullToAbsent
          ? const Value.absent()
          : Value(coachingLocation),
      coachingStylesJson: coachingStylesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(coachingStylesJson),
      sessionTypesJson: sessionTypesJson == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionTypesJson),
      hasCertification: Value(hasCertification),
      certificationName: certificationName == null && nullToAbsent
          ? const Value.absent()
          : Value(certificationName),
      views: Value(views),
      streak: Value(streak),
      createdAt: Value(createdAt),
    );
  }

  factory Provider.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Provider(
      id: serializer.fromJson<int>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      role: serializer.fromJson<String>(json['role']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String>(json['phone']),
      whatsapp: serializer.fromJson<String?>(json['whatsapp']),
      experience: serializer.fromJson<int>(json['experience']),
      coursesJson: serializer.fromJson<String>(json['coursesJson']),
      specializationsJson: serializer.fromJson<String?>(
        json['specializationsJson'],
      ),
      availabilityJson: serializer.fromJson<String>(json['availabilityJson']),
      price: serializer.fromJson<double?>(json['price']),
      rating: serializer.fromJson<double>(json['rating']),
      totalReviews: serializer.fromJson<int>(json['totalReviews']),
      totalBookings: serializer.fromJson<int>(json['totalBookings']),
      totalCalls: serializer.fromJson<int>(json['totalCalls']),
      isAvailable: serializer.fromJson<bool>(json['isAvailable']),
      profileComplete: serializer.fromJson<bool>(json['profileComplete']),
      certificationUrl: serializer.fromJson<String?>(json['certificationUrl']),
      bio: serializer.fromJson<String?>(json['bio']),
      personalityType: serializer.fromJson<String?>(json['personalityType']),
      coachingLocation: serializer.fromJson<String?>(json['coachingLocation']),
      coachingStylesJson: serializer.fromJson<String?>(
        json['coachingStylesJson'],
      ),
      sessionTypesJson: serializer.fromJson<String?>(json['sessionTypesJson']),
      hasCertification: serializer.fromJson<bool>(json['hasCertification']),
      certificationName: serializer.fromJson<String?>(
        json['certificationName'],
      ),
      views: serializer.fromJson<int>(json['views']),
      streak: serializer.fromJson<int>(json['streak']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'userId': serializer.toJson<String>(userId),
      'role': serializer.toJson<String>(role),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String>(phone),
      'whatsapp': serializer.toJson<String?>(whatsapp),
      'experience': serializer.toJson<int>(experience),
      'coursesJson': serializer.toJson<String>(coursesJson),
      'specializationsJson': serializer.toJson<String?>(specializationsJson),
      'availabilityJson': serializer.toJson<String>(availabilityJson),
      'price': serializer.toJson<double?>(price),
      'rating': serializer.toJson<double>(rating),
      'totalReviews': serializer.toJson<int>(totalReviews),
      'totalBookings': serializer.toJson<int>(totalBookings),
      'totalCalls': serializer.toJson<int>(totalCalls),
      'isAvailable': serializer.toJson<bool>(isAvailable),
      'profileComplete': serializer.toJson<bool>(profileComplete),
      'certificationUrl': serializer.toJson<String?>(certificationUrl),
      'bio': serializer.toJson<String?>(bio),
      'personalityType': serializer.toJson<String?>(personalityType),
      'coachingLocation': serializer.toJson<String?>(coachingLocation),
      'coachingStylesJson': serializer.toJson<String?>(coachingStylesJson),
      'sessionTypesJson': serializer.toJson<String?>(sessionTypesJson),
      'hasCertification': serializer.toJson<bool>(hasCertification),
      'certificationName': serializer.toJson<String?>(certificationName),
      'views': serializer.toJson<int>(views),
      'streak': serializer.toJson<int>(streak),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Provider copyWith({
    int? id,
    String? userId,
    String? role,
    String? name,
    String? phone,
    Value<String?> whatsapp = const Value.absent(),
    int? experience,
    String? coursesJson,
    Value<String?> specializationsJson = const Value.absent(),
    String? availabilityJson,
    Value<double?> price = const Value.absent(),
    double? rating,
    int? totalReviews,
    int? totalBookings,
    int? totalCalls,
    bool? isAvailable,
    bool? profileComplete,
    Value<String?> certificationUrl = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> personalityType = const Value.absent(),
    Value<String?> coachingLocation = const Value.absent(),
    Value<String?> coachingStylesJson = const Value.absent(),
    Value<String?> sessionTypesJson = const Value.absent(),
    bool? hasCertification,
    Value<String?> certificationName = const Value.absent(),
    int? views,
    int? streak,
    DateTime? createdAt,
  }) => Provider(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    role: role ?? this.role,
    name: name ?? this.name,
    phone: phone ?? this.phone,
    whatsapp: whatsapp.present ? whatsapp.value : this.whatsapp,
    experience: experience ?? this.experience,
    coursesJson: coursesJson ?? this.coursesJson,
    specializationsJson: specializationsJson.present
        ? specializationsJson.value
        : this.specializationsJson,
    availabilityJson: availabilityJson ?? this.availabilityJson,
    price: price.present ? price.value : this.price,
    rating: rating ?? this.rating,
    totalReviews: totalReviews ?? this.totalReviews,
    totalBookings: totalBookings ?? this.totalBookings,
    totalCalls: totalCalls ?? this.totalCalls,
    isAvailable: isAvailable ?? this.isAvailable,
    profileComplete: profileComplete ?? this.profileComplete,
    certificationUrl: certificationUrl.present
        ? certificationUrl.value
        : this.certificationUrl,
    bio: bio.present ? bio.value : this.bio,
    personalityType: personalityType.present
        ? personalityType.value
        : this.personalityType,
    coachingLocation: coachingLocation.present
        ? coachingLocation.value
        : this.coachingLocation,
    coachingStylesJson: coachingStylesJson.present
        ? coachingStylesJson.value
        : this.coachingStylesJson,
    sessionTypesJson: sessionTypesJson.present
        ? sessionTypesJson.value
        : this.sessionTypesJson,
    hasCertification: hasCertification ?? this.hasCertification,
    certificationName: certificationName.present
        ? certificationName.value
        : this.certificationName,
    views: views ?? this.views,
    streak: streak ?? this.streak,
    createdAt: createdAt ?? this.createdAt,
  );
  Provider copyWithCompanion(ProvidersCompanion data) {
    return Provider(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      role: data.role.present ? data.role.value : this.role,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      whatsapp: data.whatsapp.present ? data.whatsapp.value : this.whatsapp,
      experience: data.experience.present
          ? data.experience.value
          : this.experience,
      coursesJson: data.coursesJson.present
          ? data.coursesJson.value
          : this.coursesJson,
      specializationsJson: data.specializationsJson.present
          ? data.specializationsJson.value
          : this.specializationsJson,
      availabilityJson: data.availabilityJson.present
          ? data.availabilityJson.value
          : this.availabilityJson,
      price: data.price.present ? data.price.value : this.price,
      rating: data.rating.present ? data.rating.value : this.rating,
      totalReviews: data.totalReviews.present
          ? data.totalReviews.value
          : this.totalReviews,
      totalBookings: data.totalBookings.present
          ? data.totalBookings.value
          : this.totalBookings,
      totalCalls: data.totalCalls.present
          ? data.totalCalls.value
          : this.totalCalls,
      isAvailable: data.isAvailable.present
          ? data.isAvailable.value
          : this.isAvailable,
      profileComplete: data.profileComplete.present
          ? data.profileComplete.value
          : this.profileComplete,
      certificationUrl: data.certificationUrl.present
          ? data.certificationUrl.value
          : this.certificationUrl,
      bio: data.bio.present ? data.bio.value : this.bio,
      personalityType: data.personalityType.present
          ? data.personalityType.value
          : this.personalityType,
      coachingLocation: data.coachingLocation.present
          ? data.coachingLocation.value
          : this.coachingLocation,
      coachingStylesJson: data.coachingStylesJson.present
          ? data.coachingStylesJson.value
          : this.coachingStylesJson,
      sessionTypesJson: data.sessionTypesJson.present
          ? data.sessionTypesJson.value
          : this.sessionTypesJson,
      hasCertification: data.hasCertification.present
          ? data.hasCertification.value
          : this.hasCertification,
      certificationName: data.certificationName.present
          ? data.certificationName.value
          : this.certificationName,
      views: data.views.present ? data.views.value : this.views,
      streak: data.streak.present ? data.streak.value : this.streak,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Provider(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('experience: $experience, ')
          ..write('coursesJson: $coursesJson, ')
          ..write('specializationsJson: $specializationsJson, ')
          ..write('availabilityJson: $availabilityJson, ')
          ..write('price: $price, ')
          ..write('rating: $rating, ')
          ..write('totalReviews: $totalReviews, ')
          ..write('totalBookings: $totalBookings, ')
          ..write('totalCalls: $totalCalls, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('profileComplete: $profileComplete, ')
          ..write('certificationUrl: $certificationUrl, ')
          ..write('bio: $bio, ')
          ..write('personalityType: $personalityType, ')
          ..write('coachingLocation: $coachingLocation, ')
          ..write('coachingStylesJson: $coachingStylesJson, ')
          ..write('sessionTypesJson: $sessionTypesJson, ')
          ..write('hasCertification: $hasCertification, ')
          ..write('certificationName: $certificationName, ')
          ..write('views: $views, ')
          ..write('streak: $streak, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    role,
    name,
    phone,
    whatsapp,
    experience,
    coursesJson,
    specializationsJson,
    availabilityJson,
    price,
    rating,
    totalReviews,
    totalBookings,
    totalCalls,
    isAvailable,
    profileComplete,
    certificationUrl,
    bio,
    personalityType,
    coachingLocation,
    coachingStylesJson,
    sessionTypesJson,
    hasCertification,
    certificationName,
    views,
    streak,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Provider &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.role == this.role &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.whatsapp == this.whatsapp &&
          other.experience == this.experience &&
          other.coursesJson == this.coursesJson &&
          other.specializationsJson == this.specializationsJson &&
          other.availabilityJson == this.availabilityJson &&
          other.price == this.price &&
          other.rating == this.rating &&
          other.totalReviews == this.totalReviews &&
          other.totalBookings == this.totalBookings &&
          other.totalCalls == this.totalCalls &&
          other.isAvailable == this.isAvailable &&
          other.profileComplete == this.profileComplete &&
          other.certificationUrl == this.certificationUrl &&
          other.bio == this.bio &&
          other.personalityType == this.personalityType &&
          other.coachingLocation == this.coachingLocation &&
          other.coachingStylesJson == this.coachingStylesJson &&
          other.sessionTypesJson == this.sessionTypesJson &&
          other.hasCertification == this.hasCertification &&
          other.certificationName == this.certificationName &&
          other.views == this.views &&
          other.streak == this.streak &&
          other.createdAt == this.createdAt);
}

class ProvidersCompanion extends UpdateCompanion<Provider> {
  final Value<int> id;
  final Value<String> userId;
  final Value<String> role;
  final Value<String> name;
  final Value<String> phone;
  final Value<String?> whatsapp;
  final Value<int> experience;
  final Value<String> coursesJson;
  final Value<String?> specializationsJson;
  final Value<String> availabilityJson;
  final Value<double?> price;
  final Value<double> rating;
  final Value<int> totalReviews;
  final Value<int> totalBookings;
  final Value<int> totalCalls;
  final Value<bool> isAvailable;
  final Value<bool> profileComplete;
  final Value<String?> certificationUrl;
  final Value<String?> bio;
  final Value<String?> personalityType;
  final Value<String?> coachingLocation;
  final Value<String?> coachingStylesJson;
  final Value<String?> sessionTypesJson;
  final Value<bool> hasCertification;
  final Value<String?> certificationName;
  final Value<int> views;
  final Value<int> streak;
  final Value<DateTime> createdAt;
  const ProvidersCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.role = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.whatsapp = const Value.absent(),
    this.experience = const Value.absent(),
    this.coursesJson = const Value.absent(),
    this.specializationsJson = const Value.absent(),
    this.availabilityJson = const Value.absent(),
    this.price = const Value.absent(),
    this.rating = const Value.absent(),
    this.totalReviews = const Value.absent(),
    this.totalBookings = const Value.absent(),
    this.totalCalls = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.profileComplete = const Value.absent(),
    this.certificationUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.personalityType = const Value.absent(),
    this.coachingLocation = const Value.absent(),
    this.coachingStylesJson = const Value.absent(),
    this.sessionTypesJson = const Value.absent(),
    this.hasCertification = const Value.absent(),
    this.certificationName = const Value.absent(),
    this.views = const Value.absent(),
    this.streak = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProvidersCompanion.insert({
    this.id = const Value.absent(),
    required String userId,
    required String role,
    required String name,
    required String phone,
    this.whatsapp = const Value.absent(),
    this.experience = const Value.absent(),
    this.coursesJson = const Value.absent(),
    this.specializationsJson = const Value.absent(),
    this.availabilityJson = const Value.absent(),
    this.price = const Value.absent(),
    this.rating = const Value.absent(),
    this.totalReviews = const Value.absent(),
    this.totalBookings = const Value.absent(),
    this.totalCalls = const Value.absent(),
    this.isAvailable = const Value.absent(),
    this.profileComplete = const Value.absent(),
    this.certificationUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.personalityType = const Value.absent(),
    this.coachingLocation = const Value.absent(),
    this.coachingStylesJson = const Value.absent(),
    this.sessionTypesJson = const Value.absent(),
    this.hasCertification = const Value.absent(),
    this.certificationName = const Value.absent(),
    this.views = const Value.absent(),
    this.streak = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : userId = Value(userId),
       role = Value(role),
       name = Value(name),
       phone = Value(phone);
  static Insertable<Provider> custom({
    Expression<int>? id,
    Expression<String>? userId,
    Expression<String>? role,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? whatsapp,
    Expression<int>? experience,
    Expression<String>? coursesJson,
    Expression<String>? specializationsJson,
    Expression<String>? availabilityJson,
    Expression<double>? price,
    Expression<double>? rating,
    Expression<int>? totalReviews,
    Expression<int>? totalBookings,
    Expression<int>? totalCalls,
    Expression<bool>? isAvailable,
    Expression<bool>? profileComplete,
    Expression<String>? certificationUrl,
    Expression<String>? bio,
    Expression<String>? personalityType,
    Expression<String>? coachingLocation,
    Expression<String>? coachingStylesJson,
    Expression<String>? sessionTypesJson,
    Expression<bool>? hasCertification,
    Expression<String>? certificationName,
    Expression<int>? views,
    Expression<int>? streak,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (role != null) 'role': role,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (whatsapp != null) 'whatsapp': whatsapp,
      if (experience != null) 'experience': experience,
      if (coursesJson != null) 'courses_json': coursesJson,
      if (specializationsJson != null)
        'specializations_json': specializationsJson,
      if (availabilityJson != null) 'availability_json': availabilityJson,
      if (price != null) 'price': price,
      if (rating != null) 'rating': rating,
      if (totalReviews != null) 'total_reviews': totalReviews,
      if (totalBookings != null) 'total_bookings': totalBookings,
      if (totalCalls != null) 'total_calls': totalCalls,
      if (isAvailable != null) 'is_available': isAvailable,
      if (profileComplete != null) 'profile_complete': profileComplete,
      if (certificationUrl != null) 'certification_url': certificationUrl,
      if (bio != null) 'bio': bio,
      if (personalityType != null) 'personality_type': personalityType,
      if (coachingLocation != null) 'coaching_location': coachingLocation,
      if (coachingStylesJson != null)
        'coaching_styles_json': coachingStylesJson,
      if (sessionTypesJson != null) 'session_types_json': sessionTypesJson,
      if (hasCertification != null) 'has_certification': hasCertification,
      if (certificationName != null) 'certification_name': certificationName,
      if (views != null) 'views': views,
      if (streak != null) 'streak': streak,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProvidersCompanion copyWith({
    Value<int>? id,
    Value<String>? userId,
    Value<String>? role,
    Value<String>? name,
    Value<String>? phone,
    Value<String?>? whatsapp,
    Value<int>? experience,
    Value<String>? coursesJson,
    Value<String?>? specializationsJson,
    Value<String>? availabilityJson,
    Value<double?>? price,
    Value<double>? rating,
    Value<int>? totalReviews,
    Value<int>? totalBookings,
    Value<int>? totalCalls,
    Value<bool>? isAvailable,
    Value<bool>? profileComplete,
    Value<String?>? certificationUrl,
    Value<String?>? bio,
    Value<String?>? personalityType,
    Value<String?>? coachingLocation,
    Value<String?>? coachingStylesJson,
    Value<String?>? sessionTypesJson,
    Value<bool>? hasCertification,
    Value<String?>? certificationName,
    Value<int>? views,
    Value<int>? streak,
    Value<DateTime>? createdAt,
  }) {
    return ProvidersCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      experience: experience ?? this.experience,
      coursesJson: coursesJson ?? this.coursesJson,
      specializationsJson: specializationsJson ?? this.specializationsJson,
      availabilityJson: availabilityJson ?? this.availabilityJson,
      price: price ?? this.price,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalBookings: totalBookings ?? this.totalBookings,
      totalCalls: totalCalls ?? this.totalCalls,
      isAvailable: isAvailable ?? this.isAvailable,
      profileComplete: profileComplete ?? this.profileComplete,
      certificationUrl: certificationUrl ?? this.certificationUrl,
      bio: bio ?? this.bio,
      personalityType: personalityType ?? this.personalityType,
      coachingLocation: coachingLocation ?? this.coachingLocation,
      coachingStylesJson: coachingStylesJson ?? this.coachingStylesJson,
      sessionTypesJson: sessionTypesJson ?? this.sessionTypesJson,
      hasCertification: hasCertification ?? this.hasCertification,
      certificationName: certificationName ?? this.certificationName,
      views: views ?? this.views,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (whatsapp.present) {
      map['whatsapp'] = Variable<String>(whatsapp.value);
    }
    if (experience.present) {
      map['experience'] = Variable<int>(experience.value);
    }
    if (coursesJson.present) {
      map['courses_json'] = Variable<String>(coursesJson.value);
    }
    if (specializationsJson.present) {
      map['specializations_json'] = Variable<String>(specializationsJson.value);
    }
    if (availabilityJson.present) {
      map['availability_json'] = Variable<String>(availabilityJson.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (totalReviews.present) {
      map['total_reviews'] = Variable<int>(totalReviews.value);
    }
    if (totalBookings.present) {
      map['total_bookings'] = Variable<int>(totalBookings.value);
    }
    if (totalCalls.present) {
      map['total_calls'] = Variable<int>(totalCalls.value);
    }
    if (isAvailable.present) {
      map['is_available'] = Variable<bool>(isAvailable.value);
    }
    if (profileComplete.present) {
      map['profile_complete'] = Variable<bool>(profileComplete.value);
    }
    if (certificationUrl.present) {
      map['certification_url'] = Variable<String>(certificationUrl.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (personalityType.present) {
      map['personality_type'] = Variable<String>(personalityType.value);
    }
    if (coachingLocation.present) {
      map['coaching_location'] = Variable<String>(coachingLocation.value);
    }
    if (coachingStylesJson.present) {
      map['coaching_styles_json'] = Variable<String>(coachingStylesJson.value);
    }
    if (sessionTypesJson.present) {
      map['session_types_json'] = Variable<String>(sessionTypesJson.value);
    }
    if (hasCertification.present) {
      map['has_certification'] = Variable<bool>(hasCertification.value);
    }
    if (certificationName.present) {
      map['certification_name'] = Variable<String>(certificationName.value);
    }
    if (views.present) {
      map['views'] = Variable<int>(views.value);
    }
    if (streak.present) {
      map['streak'] = Variable<int>(streak.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProvidersCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('role: $role, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('whatsapp: $whatsapp, ')
          ..write('experience: $experience, ')
          ..write('coursesJson: $coursesJson, ')
          ..write('specializationsJson: $specializationsJson, ')
          ..write('availabilityJson: $availabilityJson, ')
          ..write('price: $price, ')
          ..write('rating: $rating, ')
          ..write('totalReviews: $totalReviews, ')
          ..write('totalBookings: $totalBookings, ')
          ..write('totalCalls: $totalCalls, ')
          ..write('isAvailable: $isAvailable, ')
          ..write('profileComplete: $profileComplete, ')
          ..write('certificationUrl: $certificationUrl, ')
          ..write('bio: $bio, ')
          ..write('personalityType: $personalityType, ')
          ..write('coachingLocation: $coachingLocation, ')
          ..write('coachingStylesJson: $coachingStylesJson, ')
          ..write('sessionTypesJson: $sessionTypesJson, ')
          ..write('hasCertification: $hasCertification, ')
          ..write('certificationName: $certificationName, ')
          ..write('views: $views, ')
          ..write('streak: $streak, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $InteractionsTable extends Interactions
    with TableInfo<$InteractionsTable, Interaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InteractionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _lastPromptedAtMeta = const VerificationMeta(
    'lastPromptedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPromptedAt =
      GeneratedColumn<DateTime>(
        'last_prompted_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playerId,
    providerId,
    type,
    status,
    lastPromptedAt,
    timestamp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'interactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Interaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('last_prompted_at')) {
      context.handle(
        _lastPromptedAtMeta,
        lastPromptedAt.isAcceptableOrUnknown(
          data['last_prompted_at']!,
          _lastPromptedAtMeta,
        ),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Interaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Interaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      lastPromptedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_prompted_at'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
    );
  }

  @override
  $InteractionsTable createAlias(String alias) {
    return $InteractionsTable(attachedDatabase, alias);
  }
}

class Interaction extends DataClass implements Insertable<Interaction> {
  final int id;
  final String playerId;
  final String providerId;
  final String type;
  final String status;
  final DateTime? lastPromptedAt;
  final DateTime timestamp;
  const Interaction({
    required this.id,
    required this.playerId,
    required this.providerId,
    required this.type,
    required this.status,
    this.lastPromptedAt,
    required this.timestamp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['player_id'] = Variable<String>(playerId);
    map['provider_id'] = Variable<String>(providerId);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || lastPromptedAt != null) {
      map['last_prompted_at'] = Variable<DateTime>(lastPromptedAt);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    return map;
  }

  InteractionsCompanion toCompanion(bool nullToAbsent) {
    return InteractionsCompanion(
      id: Value(id),
      playerId: Value(playerId),
      providerId: Value(providerId),
      type: Value(type),
      status: Value(status),
      lastPromptedAt: lastPromptedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPromptedAt),
      timestamp: Value(timestamp),
    );
  }

  factory Interaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Interaction(
      id: serializer.fromJson<int>(json['id']),
      playerId: serializer.fromJson<String>(json['playerId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      lastPromptedAt: serializer.fromJson<DateTime?>(json['lastPromptedAt']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playerId': serializer.toJson<String>(playerId),
      'providerId': serializer.toJson<String>(providerId),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'lastPromptedAt': serializer.toJson<DateTime?>(lastPromptedAt),
      'timestamp': serializer.toJson<DateTime>(timestamp),
    };
  }

  Interaction copyWith({
    int? id,
    String? playerId,
    String? providerId,
    String? type,
    String? status,
    Value<DateTime?> lastPromptedAt = const Value.absent(),
    DateTime? timestamp,
  }) => Interaction(
    id: id ?? this.id,
    playerId: playerId ?? this.playerId,
    providerId: providerId ?? this.providerId,
    type: type ?? this.type,
    status: status ?? this.status,
    lastPromptedAt: lastPromptedAt.present
        ? lastPromptedAt.value
        : this.lastPromptedAt,
    timestamp: timestamp ?? this.timestamp,
  );
  Interaction copyWithCompanion(InteractionsCompanion data) {
    return Interaction(
      id: data.id.present ? data.id.value : this.id,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      lastPromptedAt: data.lastPromptedAt.present
          ? data.lastPromptedAt.value
          : this.lastPromptedAt,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Interaction(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('providerId: $providerId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('lastPromptedAt: $lastPromptedAt, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    playerId,
    providerId,
    type,
    status,
    lastPromptedAt,
    timestamp,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Interaction &&
          other.id == this.id &&
          other.playerId == this.playerId &&
          other.providerId == this.providerId &&
          other.type == this.type &&
          other.status == this.status &&
          other.lastPromptedAt == this.lastPromptedAt &&
          other.timestamp == this.timestamp);
}

class InteractionsCompanion extends UpdateCompanion<Interaction> {
  final Value<int> id;
  final Value<String> playerId;
  final Value<String> providerId;
  final Value<String> type;
  final Value<String> status;
  final Value<DateTime?> lastPromptedAt;
  final Value<DateTime> timestamp;
  const InteractionsCompanion({
    this.id = const Value.absent(),
    this.playerId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.lastPromptedAt = const Value.absent(),
    this.timestamp = const Value.absent(),
  });
  InteractionsCompanion.insert({
    this.id = const Value.absent(),
    required String playerId,
    required String providerId,
    required String type,
    this.status = const Value.absent(),
    this.lastPromptedAt = const Value.absent(),
    this.timestamp = const Value.absent(),
  }) : playerId = Value(playerId),
       providerId = Value(providerId),
       type = Value(type);
  static Insertable<Interaction> custom({
    Expression<int>? id,
    Expression<String>? playerId,
    Expression<String>? providerId,
    Expression<String>? type,
    Expression<String>? status,
    Expression<DateTime>? lastPromptedAt,
    Expression<DateTime>? timestamp,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playerId != null) 'player_id': playerId,
      if (providerId != null) 'provider_id': providerId,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (lastPromptedAt != null) 'last_prompted_at': lastPromptedAt,
      if (timestamp != null) 'timestamp': timestamp,
    });
  }

  InteractionsCompanion copyWith({
    Value<int>? id,
    Value<String>? playerId,
    Value<String>? providerId,
    Value<String>? type,
    Value<String>? status,
    Value<DateTime?>? lastPromptedAt,
    Value<DateTime>? timestamp,
  }) {
    return InteractionsCompanion(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      providerId: providerId ?? this.providerId,
      type: type ?? this.type,
      status: status ?? this.status,
      lastPromptedAt: lastPromptedAt ?? this.lastPromptedAt,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (lastPromptedAt.present) {
      map['last_prompted_at'] = Variable<DateTime>(lastPromptedAt.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InteractionsCompanion(')
          ..write('id: $id, ')
          ..write('playerId: $playerId, ')
          ..write('providerId: $providerId, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('lastPromptedAt: $lastPromptedAt, ')
          ..write('timestamp: $timestamp')
          ..write(')'))
        .toString();
  }
}

class $ReviewsTable extends Reviews with TableInfo<$ReviewsTable, Review> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerIdMeta = const VerificationMeta(
    'playerId',
  );
  @override
  late final GeneratedColumn<String> playerId = GeneratedColumn<String>(
    'player_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerNameMeta = const VerificationMeta(
    'playerName',
  );
  @override
  late final GeneratedColumn<String> playerName = GeneratedColumn<String>(
    'player_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playerAvatarMeta = const VerificationMeta(
    'playerAvatar',
  );
  @override
  late final GeneratedColumn<String> playerAvatar = GeneratedColumn<String>(
    'player_avatar',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentMeta = const VerificationMeta(
    'comment',
  );
  @override
  late final GeneratedColumn<String> comment = GeneratedColumn<String>(
    'comment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    playerId,
    playerName,
    playerAvatar,
    rating,
    comment,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<Review> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('player_id')) {
      context.handle(
        _playerIdMeta,
        playerId.isAcceptableOrUnknown(data['player_id']!, _playerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_playerIdMeta);
    }
    if (data.containsKey('player_name')) {
      context.handle(
        _playerNameMeta,
        playerName.isAcceptableOrUnknown(data['player_name']!, _playerNameMeta),
      );
    } else if (isInserting) {
      context.missing(_playerNameMeta);
    }
    if (data.containsKey('player_avatar')) {
      context.handle(
        _playerAvatarMeta,
        playerAvatar.isAcceptableOrUnknown(
          data['player_avatar']!,
          _playerAvatarMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('comment')) {
      context.handle(
        _commentMeta,
        comment.isAcceptableOrUnknown(data['comment']!, _commentMeta),
      );
    } else if (isInserting) {
      context.missing(_commentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Review map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Review(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      playerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_id'],
      )!,
      playerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_name'],
      )!,
      playerAvatar: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}player_avatar'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      comment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ReviewsTable createAlias(String alias) {
    return $ReviewsTable(attachedDatabase, alias);
  }
}

class Review extends DataClass implements Insertable<Review> {
  final int id;
  final String providerId;
  final String playerId;
  final String playerName;
  final String? playerAvatar;
  final int rating;
  final String comment;
  final DateTime createdAt;
  const Review({
    required this.id,
    required this.providerId,
    required this.playerId,
    required this.playerName,
    this.playerAvatar,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['player_id'] = Variable<String>(playerId);
    map['player_name'] = Variable<String>(playerName);
    if (!nullToAbsent || playerAvatar != null) {
      map['player_avatar'] = Variable<String>(playerAvatar);
    }
    map['rating'] = Variable<int>(rating);
    map['comment'] = Variable<String>(comment);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ReviewsCompanion toCompanion(bool nullToAbsent) {
    return ReviewsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      playerId: Value(playerId),
      playerName: Value(playerName),
      playerAvatar: playerAvatar == null && nullToAbsent
          ? const Value.absent()
          : Value(playerAvatar),
      rating: Value(rating),
      comment: Value(comment),
      createdAt: Value(createdAt),
    );
  }

  factory Review.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Review(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      playerId: serializer.fromJson<String>(json['playerId']),
      playerName: serializer.fromJson<String>(json['playerName']),
      playerAvatar: serializer.fromJson<String?>(json['playerAvatar']),
      rating: serializer.fromJson<int>(json['rating']),
      comment: serializer.fromJson<String>(json['comment']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<String>(providerId),
      'playerId': serializer.toJson<String>(playerId),
      'playerName': serializer.toJson<String>(playerName),
      'playerAvatar': serializer.toJson<String?>(playerAvatar),
      'rating': serializer.toJson<int>(rating),
      'comment': serializer.toJson<String>(comment),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Review copyWith({
    int? id,
    String? providerId,
    String? playerId,
    String? playerName,
    Value<String?> playerAvatar = const Value.absent(),
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) => Review(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    playerId: playerId ?? this.playerId,
    playerName: playerName ?? this.playerName,
    playerAvatar: playerAvatar.present ? playerAvatar.value : this.playerAvatar,
    rating: rating ?? this.rating,
    comment: comment ?? this.comment,
    createdAt: createdAt ?? this.createdAt,
  );
  Review copyWithCompanion(ReviewsCompanion data) {
    return Review(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      playerId: data.playerId.present ? data.playerId.value : this.playerId,
      playerName: data.playerName.present
          ? data.playerName.value
          : this.playerName,
      playerAvatar: data.playerAvatar.present
          ? data.playerAvatar.value
          : this.playerAvatar,
      rating: data.rating.present ? data.rating.value : this.rating,
      comment: data.comment.present ? data.comment.value : this.comment,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Review(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('playerId: $playerId, ')
          ..write('playerName: $playerName, ')
          ..write('playerAvatar: $playerAvatar, ')
          ..write('rating: $rating, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    playerId,
    playerName,
    playerAvatar,
    rating,
    comment,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Review &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.playerId == this.playerId &&
          other.playerName == this.playerName &&
          other.playerAvatar == this.playerAvatar &&
          other.rating == this.rating &&
          other.comment == this.comment &&
          other.createdAt == this.createdAt);
}

class ReviewsCompanion extends UpdateCompanion<Review> {
  final Value<int> id;
  final Value<String> providerId;
  final Value<String> playerId;
  final Value<String> playerName;
  final Value<String?> playerAvatar;
  final Value<int> rating;
  final Value<String> comment;
  final Value<DateTime> createdAt;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.playerId = const Value.absent(),
    this.playerName = const Value.absent(),
    this.playerAvatar = const Value.absent(),
    this.rating = const Value.absent(),
    this.comment = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ReviewsCompanion.insert({
    this.id = const Value.absent(),
    required String providerId,
    required String playerId,
    required String playerName,
    this.playerAvatar = const Value.absent(),
    required int rating,
    required String comment,
    this.createdAt = const Value.absent(),
  }) : providerId = Value(providerId),
       playerId = Value(playerId),
       playerName = Value(playerName),
       rating = Value(rating),
       comment = Value(comment);
  static Insertable<Review> custom({
    Expression<int>? id,
    Expression<String>? providerId,
    Expression<String>? playerId,
    Expression<String>? playerName,
    Expression<String>? playerAvatar,
    Expression<int>? rating,
    Expression<String>? comment,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (playerId != null) 'player_id': playerId,
      if (playerName != null) 'player_name': playerName,
      if (playerAvatar != null) 'player_avatar': playerAvatar,
      if (rating != null) 'rating': rating,
      if (comment != null) 'comment': comment,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ReviewsCompanion copyWith({
    Value<int>? id,
    Value<String>? providerId,
    Value<String>? playerId,
    Value<String>? playerName,
    Value<String?>? playerAvatar,
    Value<int>? rating,
    Value<String>? comment,
    Value<DateTime>? createdAt,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      playerAvatar: playerAvatar ?? this.playerAvatar,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (playerId.present) {
      map['player_id'] = Variable<String>(playerId.value);
    }
    if (playerName.present) {
      map['player_name'] = Variable<String>(playerName.value);
    }
    if (playerAvatar.present) {
      map['player_avatar'] = Variable<String>(playerAvatar.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (comment.present) {
      map['comment'] = Variable<String>(comment.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('playerId: $playerId, ')
          ..write('playerName: $playerName, ')
          ..write('playerAvatar: $playerAvatar, ')
          ..write('rating: $rating, ')
          ..write('comment: $comment, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserProfilesTable userProfiles = $UserProfilesTable(this);
  late final $CoursesTable courses = $CoursesTable(this);
  late final $RoundsTable rounds = $RoundsTable(this);
  late final $GroupRoundsTable groupRounds = $GroupRoundsTable(this);
  late final $HoleScoresTable holeScores = $HoleScoresTable(this);
  late final $ClubsTable clubs = $ClubsTable(this);
  late final $FriendsTable friends = $FriendsTable(this);
  late final $GroupRoundParticipantsTable groupRoundParticipants =
      $GroupRoundParticipantsTable(this);
  late final $DrillsTable drills = $DrillsTable(this);
  late final $PracticeSessionsTable practiceSessions = $PracticeSessionsTable(
    this,
  );
  late final $PracticeShotsTable practiceShots = $PracticeShotsTable(this);
  late final $DrillStepsTable drillSteps = $DrillStepsTable(this);
  late final $ProvidersTable providers = $ProvidersTable(this);
  late final $InteractionsTable interactions = $InteractionsTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    userProfiles,
    courses,
    rounds,
    groupRounds,
    holeScores,
    clubs,
    friends,
    groupRoundParticipants,
    drills,
    practiceSessions,
    practiceShots,
    drillSteps,
    providers,
    interactions,
    reviews,
  ];
}

typedef $$UserProfilesTableCreateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String?> firebaseUid,
      Value<String?> email,
      Value<String> name,
      Value<String?> avatarUrl,
      Value<double?> handicap,
      Value<int?> homeCourseId,
      Value<String?> homeCourseName,
      Value<String?> skillLevel,
      Value<String?> preferredTees,
      Value<String?> playStyle,
      Value<String> units,
      Value<String> themeMode,
      Value<String> privacyLevel,
      Value<String> badgesJson,
      Value<String?> role,
      Value<bool> profileComplete,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$UserProfilesTableUpdateCompanionBuilder =
    UserProfilesCompanion Function({
      Value<int> id,
      Value<String?> firebaseUid,
      Value<String?> email,
      Value<String> name,
      Value<String?> avatarUrl,
      Value<double?> handicap,
      Value<int?> homeCourseId,
      Value<String?> homeCourseName,
      Value<String?> skillLevel,
      Value<String?> preferredTees,
      Value<String?> playStyle,
      Value<String> units,
      Value<String> themeMode,
      Value<String> privacyLevel,
      Value<String> badgesJson,
      Value<String?> role,
      Value<bool> profileComplete,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

class $$UserProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firebaseUid => $composableBuilder(
    column: $table.firebaseUid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get handicap => $composableBuilder(
    column: $table.handicap,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeCourseId => $composableBuilder(
    column: $table.homeCourseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get homeCourseName => $composableBuilder(
    column: $table.homeCourseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skillLevel => $composableBuilder(
    column: $table.skillLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preferredTees => $composableBuilder(
    column: $table.preferredTees,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playStyle => $composableBuilder(
    column: $table.playStyle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get profileComplete => $composableBuilder(
    column: $table.profileComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firebaseUid => $composableBuilder(
    column: $table.firebaseUid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get handicap => $composableBuilder(
    column: $table.handicap,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeCourseId => $composableBuilder(
    column: $table.homeCourseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get homeCourseName => $composableBuilder(
    column: $table.homeCourseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skillLevel => $composableBuilder(
    column: $table.skillLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preferredTees => $composableBuilder(
    column: $table.preferredTees,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playStyle => $composableBuilder(
    column: $table.playStyle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get profileComplete => $composableBuilder(
    column: $table.profileComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserProfilesTable> {
  $$UserProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firebaseUid => $composableBuilder(
    column: $table.firebaseUid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<double> get handicap =>
      $composableBuilder(column: $table.handicap, builder: (column) => column);

  GeneratedColumn<int> get homeCourseId => $composableBuilder(
    column: $table.homeCourseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get homeCourseName => $composableBuilder(
    column: $table.homeCourseName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skillLevel => $composableBuilder(
    column: $table.skillLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preferredTees => $composableBuilder(
    column: $table.preferredTees,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playStyle =>
      $composableBuilder(column: $table.playStyle, builder: (column) => column);

  GeneratedColumn<String> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get privacyLevel => $composableBuilder(
    column: $table.privacyLevel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get badgesJson => $composableBuilder(
    column: $table.badgesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<bool> get profileComplete => $composableBuilder(
    column: $table.profileComplete,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$UserProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserProfilesTable,
          UserProfile,
          $$UserProfilesTableFilterComposer,
          $$UserProfilesTableOrderingComposer,
          $$UserProfilesTableAnnotationComposer,
          $$UserProfilesTableCreateCompanionBuilder,
          $$UserProfilesTableUpdateCompanionBuilder,
          (
            UserProfile,
            BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
          ),
          UserProfile,
          PrefetchHooks Function()
        > {
  $$UserProfilesTableTableManager(_$AppDatabase db, $UserProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> firebaseUid = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<double?> handicap = const Value.absent(),
                Value<int?> homeCourseId = const Value.absent(),
                Value<String?> homeCourseName = const Value.absent(),
                Value<String?> skillLevel = const Value.absent(),
                Value<String?> preferredTees = const Value.absent(),
                Value<String?> playStyle = const Value.absent(),
                Value<String> units = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> privacyLevel = const Value.absent(),
                Value<String> badgesJson = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<bool> profileComplete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion(
                id: id,
                firebaseUid: firebaseUid,
                email: email,
                name: name,
                avatarUrl: avatarUrl,
                handicap: handicap,
                homeCourseId: homeCourseId,
                homeCourseName: homeCourseName,
                skillLevel: skillLevel,
                preferredTees: preferredTees,
                playStyle: playStyle,
                units: units,
                themeMode: themeMode,
                privacyLevel: privacyLevel,
                badgesJson: badgesJson,
                role: role,
                profileComplete: profileComplete,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> firebaseUid = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<double?> handicap = const Value.absent(),
                Value<int?> homeCourseId = const Value.absent(),
                Value<String?> homeCourseName = const Value.absent(),
                Value<String?> skillLevel = const Value.absent(),
                Value<String?> preferredTees = const Value.absent(),
                Value<String?> playStyle = const Value.absent(),
                Value<String> units = const Value.absent(),
                Value<String> themeMode = const Value.absent(),
                Value<String> privacyLevel = const Value.absent(),
                Value<String> badgesJson = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<bool> profileComplete = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => UserProfilesCompanion.insert(
                id: id,
                firebaseUid: firebaseUid,
                email: email,
                name: name,
                avatarUrl: avatarUrl,
                handicap: handicap,
                homeCourseId: homeCourseId,
                homeCourseName: homeCourseName,
                skillLevel: skillLevel,
                preferredTees: preferredTees,
                playStyle: playStyle,
                units: units,
                themeMode: themeMode,
                privacyLevel: privacyLevel,
                badgesJson: badgesJson,
                role: role,
                profileComplete: profileComplete,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserProfilesTable,
      UserProfile,
      $$UserProfilesTableFilterComposer,
      $$UserProfilesTableOrderingComposer,
      $$UserProfilesTableAnnotationComposer,
      $$UserProfilesTableCreateCompanionBuilder,
      $$UserProfilesTableUpdateCompanionBuilder,
      (
        UserProfile,
        BaseReferences<_$AppDatabase, $UserProfilesTable, UserProfile>,
      ),
      UserProfile,
      PrefetchHooks Function()
    >;
typedef $$CoursesTableCreateCompanionBuilder =
    CoursesCompanion Function({
      Value<int> id,
      Value<String?> firestoreId,
      Value<String?> userId,
      required String name,
      Value<String> location,
      Value<int> totalHoles,
      Value<int?> par18,
      Value<int?> par9front,
      Value<int?> par9back,
      Value<String> holePars,
      Value<String> teeData,
      Value<bool> isUserEdited,
      Value<String?> syncId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$CoursesTableUpdateCompanionBuilder =
    CoursesCompanion Function({
      Value<int> id,
      Value<String?> firestoreId,
      Value<String?> userId,
      Value<String> name,
      Value<String> location,
      Value<int> totalHoles,
      Value<int?> par18,
      Value<int?> par9front,
      Value<int?> par9back,
      Value<String> holePars,
      Value<String> teeData,
      Value<bool> isUserEdited,
      Value<String?> syncId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$CoursesTableReferences
    extends BaseReferences<_$AppDatabase, $CoursesTable, Course> {
  $$CoursesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RoundsTable, List<Round>> _roundsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rounds,
    aliasName: $_aliasNameGenerator(db.courses.id, db.rounds.courseId),
  );

  $$RoundsTableProcessedTableManager get roundsRefs {
    final manager = $$RoundsTableTableManager(
      $_db,
      $_db.rounds,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_roundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GroupRoundsTable, List<GroupRound>>
  _groupRoundsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.groupRounds,
    aliasName: $_aliasNameGenerator(db.courses.id, db.groupRounds.courseId),
  );

  $$GroupRoundsTableProcessedTableManager get groupRoundsRefs {
    final manager = $$GroupRoundsTableTableManager(
      $_db,
      $_db.groupRounds,
    ).filter((f) => f.courseId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_groupRoundsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CoursesTableFilterComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalHoles => $composableBuilder(
    column: $table.totalHoles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get par18 => $composableBuilder(
    column: $table.par18,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get par9front => $composableBuilder(
    column: $table.par9front,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get par9back => $composableBuilder(
    column: $table.par9back,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get holePars => $composableBuilder(
    column: $table.holePars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get teeData => $composableBuilder(
    column: $table.teeData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUserEdited => $composableBuilder(
    column: $table.isUserEdited,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> roundsRefs(
    Expression<bool> Function($$RoundsTableFilterComposer f) f,
  ) {
    final $$RoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableFilterComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> groupRoundsRefs(
    Expression<bool> Function($$GroupRoundsTableFilterComposer f) f,
  ) {
    final $$GroupRoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableFilterComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableOrderingComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalHoles => $composableBuilder(
    column: $table.totalHoles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get par18 => $composableBuilder(
    column: $table.par18,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get par9front => $composableBuilder(
    column: $table.par9front,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get par9back => $composableBuilder(
    column: $table.par9back,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get holePars => $composableBuilder(
    column: $table.holePars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get teeData => $composableBuilder(
    column: $table.teeData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUserEdited => $composableBuilder(
    column: $table.isUserEdited,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CoursesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CoursesTable> {
  $$CoursesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<int> get totalHoles => $composableBuilder(
    column: $table.totalHoles,
    builder: (column) => column,
  );

  GeneratedColumn<int> get par18 =>
      $composableBuilder(column: $table.par18, builder: (column) => column);

  GeneratedColumn<int> get par9front =>
      $composableBuilder(column: $table.par9front, builder: (column) => column);

  GeneratedColumn<int> get par9back =>
      $composableBuilder(column: $table.par9back, builder: (column) => column);

  GeneratedColumn<String> get holePars =>
      $composableBuilder(column: $table.holePars, builder: (column) => column);

  GeneratedColumn<String> get teeData =>
      $composableBuilder(column: $table.teeData, builder: (column) => column);

  GeneratedColumn<bool> get isUserEdited => $composableBuilder(
    column: $table.isUserEdited,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> roundsRefs<T extends Object>(
    Expression<T> Function($$RoundsTableAnnotationComposer a) f,
  ) {
    final $$RoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> groupRoundsRefs<T extends Object>(
    Expression<T> Function($$GroupRoundsTableAnnotationComposer a) f,
  ) {
    final $$GroupRoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.courseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CoursesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CoursesTable,
          Course,
          $$CoursesTableFilterComposer,
          $$CoursesTableOrderingComposer,
          $$CoursesTableAnnotationComposer,
          $$CoursesTableCreateCompanionBuilder,
          $$CoursesTableUpdateCompanionBuilder,
          (Course, $$CoursesTableReferences),
          Course,
          PrefetchHooks Function({bool roundsRefs, bool groupRoundsRefs})
        > {
  $$CoursesTableTableManager(_$AppDatabase db, $CoursesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CoursesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CoursesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CoursesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> location = const Value.absent(),
                Value<int> totalHoles = const Value.absent(),
                Value<int?> par18 = const Value.absent(),
                Value<int?> par9front = const Value.absent(),
                Value<int?> par9back = const Value.absent(),
                Value<String> holePars = const Value.absent(),
                Value<String> teeData = const Value.absent(),
                Value<bool> isUserEdited = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoursesCompanion(
                id: id,
                firestoreId: firestoreId,
                userId: userId,
                name: name,
                location: location,
                totalHoles: totalHoles,
                par18: par18,
                par9front: par9front,
                par9back: par9back,
                holePars: holePars,
                teeData: teeData,
                isUserEdited: isUserEdited,
                syncId: syncId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required String name,
                Value<String> location = const Value.absent(),
                Value<int> totalHoles = const Value.absent(),
                Value<int?> par18 = const Value.absent(),
                Value<int?> par9front = const Value.absent(),
                Value<int?> par9back = const Value.absent(),
                Value<String> holePars = const Value.absent(),
                Value<String> teeData = const Value.absent(),
                Value<bool> isUserEdited = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => CoursesCompanion.insert(
                id: id,
                firestoreId: firestoreId,
                userId: userId,
                name: name,
                location: location,
                totalHoles: totalHoles,
                par18: par18,
                par9front: par9front,
                par9back: par9back,
                holePars: holePars,
                teeData: teeData,
                isUserEdited: isUserEdited,
                syncId: syncId,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CoursesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({roundsRefs = false, groupRoundsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (roundsRefs) db.rounds,
                    if (groupRoundsRefs) db.groupRounds,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (roundsRefs)
                        await $_getPrefetchedData<Course, $CoursesTable, Round>(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._roundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).roundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (groupRoundsRefs)
                        await $_getPrefetchedData<
                          Course,
                          $CoursesTable,
                          GroupRound
                        >(
                          currentTable: table,
                          referencedTable: $$CoursesTableReferences
                              ._groupRoundsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CoursesTableReferences(
                                db,
                                table,
                                p0,
                              ).groupRoundsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.courseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CoursesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CoursesTable,
      Course,
      $$CoursesTableFilterComposer,
      $$CoursesTableOrderingComposer,
      $$CoursesTableAnnotationComposer,
      $$CoursesTableCreateCompanionBuilder,
      $$CoursesTableUpdateCompanionBuilder,
      (Course, $$CoursesTableReferences),
      Course,
      PrefetchHooks Function({bool roundsRefs, bool groupRoundsRefs})
    >;
typedef $$RoundsTableCreateCompanionBuilder =
    RoundsCompanion Function({
      Value<int> id,
      Value<String?> firestoreId,
      Value<String?> userId,
      required int courseId,
      Value<String> courseName,
      Value<int> holesPlayed,
      Value<String> tee,
      required int totalScore,
      required int coursePar,
      required int scoreVsPar,
      Value<int?> front9Score,
      Value<int?> back9Score,
      Value<String> notes,
      Value<String?> syncId,
      Value<DateTime> playedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$RoundsTableUpdateCompanionBuilder =
    RoundsCompanion Function({
      Value<int> id,
      Value<String?> firestoreId,
      Value<String?> userId,
      Value<int> courseId,
      Value<String> courseName,
      Value<int> holesPlayed,
      Value<String> tee,
      Value<int> totalScore,
      Value<int> coursePar,
      Value<int> scoreVsPar,
      Value<int?> front9Score,
      Value<int?> back9Score,
      Value<String> notes,
      Value<String?> syncId,
      Value<DateTime> playedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$RoundsTableReferences
    extends BaseReferences<_$AppDatabase, $RoundsTable, Round> {
  $$RoundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) => db.courses
      .createAlias($_aliasNameGenerator(db.rounds.courseId, db.courses.id));

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<int>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HoleScoresTable, List<HoleScore>>
  _holeScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.holeScores,
    aliasName: $_aliasNameGenerator(db.rounds.id, db.holeScores.roundId),
  );

  $$HoleScoresTableProcessedTableManager get holeScoresRefs {
    final manager = $$HoleScoresTableTableManager(
      $_db,
      $_db.holeScores,
    ).filter((f) => f.roundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_holeScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RoundsTableFilterComposer
    extends Composer<_$AppDatabase, $RoundsTable> {
  $$RoundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holesPlayed => $composableBuilder(
    column: $table.holesPlayed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tee => $composableBuilder(
    column: $table.tee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get coursePar => $composableBuilder(
    column: $table.coursePar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoreVsPar => $composableBuilder(
    column: $table.scoreVsPar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get front9Score => $composableBuilder(
    column: $table.front9Score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get back9Score => $composableBuilder(
    column: $table.back9Score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> holeScoresRefs(
    Expression<bool> Function($$HoleScoresTableFilterComposer f) f,
  ) {
    final $$HoleScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeScores,
      getReferencedColumn: (t) => t.roundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleScoresTableFilterComposer(
            $db: $db,
            $table: $db.holeScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoundsTableOrderingComposer
    extends Composer<_$AppDatabase, $RoundsTable> {
  $$RoundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holesPlayed => $composableBuilder(
    column: $table.holesPlayed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tee => $composableBuilder(
    column: $table.tee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get coursePar => $composableBuilder(
    column: $table.coursePar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoreVsPar => $composableBuilder(
    column: $table.scoreVsPar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get front9Score => $composableBuilder(
    column: $table.front9Score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get back9Score => $composableBuilder(
    column: $table.back9Score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncId => $composableBuilder(
    column: $table.syncId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RoundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RoundsTable> {
  $$RoundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get courseName => $composableBuilder(
    column: $table.courseName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get holesPlayed => $composableBuilder(
    column: $table.holesPlayed,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tee =>
      $composableBuilder(column: $table.tee, builder: (column) => column);

  GeneratedColumn<int> get totalScore => $composableBuilder(
    column: $table.totalScore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get coursePar =>
      $composableBuilder(column: $table.coursePar, builder: (column) => column);

  GeneratedColumn<int> get scoreVsPar => $composableBuilder(
    column: $table.scoreVsPar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get front9Score => $composableBuilder(
    column: $table.front9Score,
    builder: (column) => column,
  );

  GeneratedColumn<int> get back9Score => $composableBuilder(
    column: $table.back9Score,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get syncId =>
      $composableBuilder(column: $table.syncId, builder: (column) => column);

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> holeScoresRefs<T extends Object>(
    Expression<T> Function($$HoleScoresTableAnnotationComposer a) f,
  ) {
    final $$HoleScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeScores,
      getReferencedColumn: (t) => t.roundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.holeScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RoundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RoundsTable,
          Round,
          $$RoundsTableFilterComposer,
          $$RoundsTableOrderingComposer,
          $$RoundsTableAnnotationComposer,
          $$RoundsTableCreateCompanionBuilder,
          $$RoundsTableUpdateCompanionBuilder,
          (Round, $$RoundsTableReferences),
          Round,
          PrefetchHooks Function({bool courseId, bool holeScoresRefs})
        > {
  $$RoundsTableTableManager(_$AppDatabase db, $RoundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RoundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RoundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RoundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<int> courseId = const Value.absent(),
                Value<String> courseName = const Value.absent(),
                Value<int> holesPlayed = const Value.absent(),
                Value<String> tee = const Value.absent(),
                Value<int> totalScore = const Value.absent(),
                Value<int> coursePar = const Value.absent(),
                Value<int> scoreVsPar = const Value.absent(),
                Value<int?> front9Score = const Value.absent(),
                Value<int?> back9Score = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoundsCompanion(
                id: id,
                firestoreId: firestoreId,
                userId: userId,
                courseId: courseId,
                courseName: courseName,
                holesPlayed: holesPlayed,
                tee: tee,
                totalScore: totalScore,
                coursePar: coursePar,
                scoreVsPar: scoreVsPar,
                front9Score: front9Score,
                back9Score: back9Score,
                notes: notes,
                syncId: syncId,
                playedAt: playedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required int courseId,
                Value<String> courseName = const Value.absent(),
                Value<int> holesPlayed = const Value.absent(),
                Value<String> tee = const Value.absent(),
                required int totalScore,
                required int coursePar,
                required int scoreVsPar,
                Value<int?> front9Score = const Value.absent(),
                Value<int?> back9Score = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> syncId = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => RoundsCompanion.insert(
                id: id,
                firestoreId: firestoreId,
                userId: userId,
                courseId: courseId,
                courseName: courseName,
                holesPlayed: holesPlayed,
                tee: tee,
                totalScore: totalScore,
                coursePar: coursePar,
                scoreVsPar: scoreVsPar,
                front9Score: front9Score,
                back9Score: back9Score,
                notes: notes,
                syncId: syncId,
                playedAt: playedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$RoundsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({courseId = false, holeScoresRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (holeScoresRefs) db.holeScores],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (courseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.courseId,
                                referencedTable: $$RoundsTableReferences
                                    ._courseIdTable(db),
                                referencedColumn: $$RoundsTableReferences
                                    ._courseIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (holeScoresRefs)
                    await $_getPrefetchedData<Round, $RoundsTable, HoleScore>(
                      currentTable: table,
                      referencedTable: $$RoundsTableReferences
                          ._holeScoresRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RoundsTableReferences(db, table, p0).holeScoresRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.roundId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RoundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RoundsTable,
      Round,
      $$RoundsTableFilterComposer,
      $$RoundsTableOrderingComposer,
      $$RoundsTableAnnotationComposer,
      $$RoundsTableCreateCompanionBuilder,
      $$RoundsTableUpdateCompanionBuilder,
      (Round, $$RoundsTableReferences),
      Round,
      PrefetchHooks Function({bool courseId, bool holeScoresRefs})
    >;
typedef $$GroupRoundsTableCreateCompanionBuilder =
    GroupRoundsCompanion Function({
      Value<int> id,
      required String roundCode,
      required String captainId,
      required int courseId,
      Value<String> status,
      Value<String> scoringMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$GroupRoundsTableUpdateCompanionBuilder =
    GroupRoundsCompanion Function({
      Value<int> id,
      Value<String> roundCode,
      Value<String> captainId,
      Value<int> courseId,
      Value<String> status,
      Value<String> scoringMode,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$GroupRoundsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupRoundsTable, GroupRound> {
  $$GroupRoundsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CoursesTable _courseIdTable(_$AppDatabase db) =>
      db.courses.createAlias(
        $_aliasNameGenerator(db.groupRounds.courseId, db.courses.id),
      );

  $$CoursesTableProcessedTableManager get courseId {
    final $_column = $_itemColumn<int>('course_id')!;

    final manager = $$CoursesTableTableManager(
      $_db,
      $_db.courses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_courseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HoleScoresTable, List<HoleScore>>
  _holeScoresRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.holeScores,
    aliasName: $_aliasNameGenerator(
      db.groupRounds.id,
      db.holeScores.groupRoundId,
    ),
  );

  $$HoleScoresTableProcessedTableManager get holeScoresRefs {
    final manager = $$HoleScoresTableTableManager(
      $_db,
      $_db.holeScores,
    ).filter((f) => f.groupRoundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_holeScoresRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $GroupRoundParticipantsTable,
    List<GroupRoundParticipant>
  >
  _groupRoundParticipantsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.groupRoundParticipants,
        aliasName: $_aliasNameGenerator(
          db.groupRounds.id,
          db.groupRoundParticipants.groupRoundId,
        ),
      );

  $$GroupRoundParticipantsTableProcessedTableManager
  get groupRoundParticipantsRefs {
    final manager = $$GroupRoundParticipantsTableTableManager(
      $_db,
      $_db.groupRoundParticipants,
    ).filter((f) => f.groupRoundId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _groupRoundParticipantsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupRoundsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupRoundsTable> {
  $$GroupRoundsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get roundCode => $composableBuilder(
    column: $table.roundCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get captainId => $composableBuilder(
    column: $table.captainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CoursesTableFilterComposer get courseId {
    final $$CoursesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableFilterComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> holeScoresRefs(
    Expression<bool> Function($$HoleScoresTableFilterComposer f) f,
  ) {
    final $$HoleScoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeScores,
      getReferencedColumn: (t) => t.groupRoundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleScoresTableFilterComposer(
            $db: $db,
            $table: $db.holeScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> groupRoundParticipantsRefs(
    Expression<bool> Function($$GroupRoundParticipantsTableFilterComposer f) f,
  ) {
    final $$GroupRoundParticipantsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.groupRoundParticipants,
          getReferencedColumn: (t) => t.groupRoundId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GroupRoundParticipantsTableFilterComposer(
                $db: $db,
                $table: $db.groupRoundParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GroupRoundsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupRoundsTable> {
  $$GroupRoundsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get roundCode => $composableBuilder(
    column: $table.roundCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get captainId => $composableBuilder(
    column: $table.captainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CoursesTableOrderingComposer get courseId {
    final $$CoursesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableOrderingComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupRoundsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupRoundsTable> {
  $$GroupRoundsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roundCode =>
      $composableBuilder(column: $table.roundCode, builder: (column) => column);

  GeneratedColumn<String> get captainId =>
      $composableBuilder(column: $table.captainId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get scoringMode => $composableBuilder(
    column: $table.scoringMode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CoursesTableAnnotationComposer get courseId {
    final $$CoursesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.courseId,
      referencedTable: $db.courses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CoursesTableAnnotationComposer(
            $db: $db,
            $table: $db.courses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> holeScoresRefs<T extends Object>(
    Expression<T> Function($$HoleScoresTableAnnotationComposer a) f,
  ) {
    final $$HoleScoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.holeScores,
      getReferencedColumn: (t) => t.groupRoundId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HoleScoresTableAnnotationComposer(
            $db: $db,
            $table: $db.holeScores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> groupRoundParticipantsRefs<T extends Object>(
    Expression<T> Function($$GroupRoundParticipantsTableAnnotationComposer a) f,
  ) {
    final $$GroupRoundParticipantsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.groupRoundParticipants,
          getReferencedColumn: (t) => t.groupRoundId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$GroupRoundParticipantsTableAnnotationComposer(
                $db: $db,
                $table: $db.groupRoundParticipants,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$GroupRoundsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupRoundsTable,
          GroupRound,
          $$GroupRoundsTableFilterComposer,
          $$GroupRoundsTableOrderingComposer,
          $$GroupRoundsTableAnnotationComposer,
          $$GroupRoundsTableCreateCompanionBuilder,
          $$GroupRoundsTableUpdateCompanionBuilder,
          (GroupRound, $$GroupRoundsTableReferences),
          GroupRound,
          PrefetchHooks Function({
            bool courseId,
            bool holeScoresRefs,
            bool groupRoundParticipantsRefs,
          })
        > {
  $$GroupRoundsTableTableManager(_$AppDatabase db, $GroupRoundsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupRoundsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupRoundsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupRoundsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> roundCode = const Value.absent(),
                Value<String> captainId = const Value.absent(),
                Value<int> courseId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> scoringMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GroupRoundsCompanion(
                id: id,
                roundCode: roundCode,
                captainId: captainId,
                courseId: courseId,
                status: status,
                scoringMode: scoringMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String roundCode,
                required String captainId,
                required int courseId,
                Value<String> status = const Value.absent(),
                Value<String> scoringMode = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => GroupRoundsCompanion.insert(
                id: id,
                roundCode: roundCode,
                captainId: captainId,
                courseId: courseId,
                status: status,
                scoringMode: scoringMode,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GroupRoundsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                courseId = false,
                holeScoresRefs = false,
                groupRoundParticipantsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (holeScoresRefs) db.holeScores,
                    if (groupRoundParticipantsRefs) db.groupRoundParticipants,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (courseId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.courseId,
                                    referencedTable:
                                        $$GroupRoundsTableReferences
                                            ._courseIdTable(db),
                                    referencedColumn:
                                        $$GroupRoundsTableReferences
                                            ._courseIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (holeScoresRefs)
                        await $_getPrefetchedData<
                          GroupRound,
                          $GroupRoundsTable,
                          HoleScore
                        >(
                          currentTable: table,
                          referencedTable: $$GroupRoundsTableReferences
                              ._holeScoresRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupRoundsTableReferences(
                                db,
                                table,
                                p0,
                              ).holeScoresRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupRoundId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (groupRoundParticipantsRefs)
                        await $_getPrefetchedData<
                          GroupRound,
                          $GroupRoundsTable,
                          GroupRoundParticipant
                        >(
                          currentTable: table,
                          referencedTable: $$GroupRoundsTableReferences
                              ._groupRoundParticipantsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupRoundsTableReferences(
                                db,
                                table,
                                p0,
                              ).groupRoundParticipantsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.groupRoundId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GroupRoundsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupRoundsTable,
      GroupRound,
      $$GroupRoundsTableFilterComposer,
      $$GroupRoundsTableOrderingComposer,
      $$GroupRoundsTableAnnotationComposer,
      $$GroupRoundsTableCreateCompanionBuilder,
      $$GroupRoundsTableUpdateCompanionBuilder,
      (GroupRound, $$GroupRoundsTableReferences),
      GroupRound,
      PrefetchHooks Function({
        bool courseId,
        bool holeScoresRefs,
        bool groupRoundParticipantsRefs,
      })
    >;
typedef $$HoleScoresTableCreateCompanionBuilder =
    HoleScoresCompanion Function({
      Value<int> id,
      required int roundId,
      required int holeNumber,
      required int par,
      required int score,
      Value<int?> yardage,
      Value<int?> putts,
      Value<String?> fairwayHit,
      Value<int?> penalties,
      Value<int?> groupRoundId,
    });
typedef $$HoleScoresTableUpdateCompanionBuilder =
    HoleScoresCompanion Function({
      Value<int> id,
      Value<int> roundId,
      Value<int> holeNumber,
      Value<int> par,
      Value<int> score,
      Value<int?> yardage,
      Value<int?> putts,
      Value<String?> fairwayHit,
      Value<int?> penalties,
      Value<int?> groupRoundId,
    });

final class $$HoleScoresTableReferences
    extends BaseReferences<_$AppDatabase, $HoleScoresTable, HoleScore> {
  $$HoleScoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RoundsTable _roundIdTable(_$AppDatabase db) => db.rounds.createAlias(
    $_aliasNameGenerator(db.holeScores.roundId, db.rounds.id),
  );

  $$RoundsTableProcessedTableManager get roundId {
    final $_column = $_itemColumn<int>('round_id')!;

    final manager = $$RoundsTableTableManager(
      $_db,
      $_db.rounds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_roundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GroupRoundsTable _groupRoundIdTable(_$AppDatabase db) =>
      db.groupRounds.createAlias(
        $_aliasNameGenerator(db.holeScores.groupRoundId, db.groupRounds.id),
      );

  $$GroupRoundsTableProcessedTableManager? get groupRoundId {
    final $_column = $_itemColumn<int>('group_round_id');
    if ($_column == null) return null;
    final manager = $$GroupRoundsTableTableManager(
      $_db,
      $_db.groupRounds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupRoundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HoleScoresTableFilterComposer
    extends Composer<_$AppDatabase, $HoleScoresTable> {
  $$HoleScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get holeNumber => $composableBuilder(
    column: $table.holeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get par => $composableBuilder(
    column: $table.par,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yardage => $composableBuilder(
    column: $table.yardage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get putts => $composableBuilder(
    column: $table.putts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fairwayHit => $composableBuilder(
    column: $table.fairwayHit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get penalties => $composableBuilder(
    column: $table.penalties,
    builder: (column) => ColumnFilters(column),
  );

  $$RoundsTableFilterComposer get roundId {
    final $$RoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundId,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableFilterComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupRoundsTableFilterComposer get groupRoundId {
    final $$GroupRoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupRoundId,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableFilterComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoleScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $HoleScoresTable> {
  $$HoleScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get holeNumber => $composableBuilder(
    column: $table.holeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get par => $composableBuilder(
    column: $table.par,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yardage => $composableBuilder(
    column: $table.yardage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get putts => $composableBuilder(
    column: $table.putts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fairwayHit => $composableBuilder(
    column: $table.fairwayHit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get penalties => $composableBuilder(
    column: $table.penalties,
    builder: (column) => ColumnOrderings(column),
  );

  $$RoundsTableOrderingComposer get roundId {
    final $$RoundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundId,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableOrderingComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupRoundsTableOrderingComposer get groupRoundId {
    final $$GroupRoundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupRoundId,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableOrderingComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoleScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $HoleScoresTable> {
  $$HoleScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get holeNumber => $composableBuilder(
    column: $table.holeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get par =>
      $composableBuilder(column: $table.par, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get yardage =>
      $composableBuilder(column: $table.yardage, builder: (column) => column);

  GeneratedColumn<int> get putts =>
      $composableBuilder(column: $table.putts, builder: (column) => column);

  GeneratedColumn<String> get fairwayHit => $composableBuilder(
    column: $table.fairwayHit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get penalties =>
      $composableBuilder(column: $table.penalties, builder: (column) => column);

  $$RoundsTableAnnotationComposer get roundId {
    final $$RoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.roundId,
      referencedTable: $db.rounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.rounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupRoundsTableAnnotationComposer get groupRoundId {
    final $$GroupRoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupRoundId,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HoleScoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HoleScoresTable,
          HoleScore,
          $$HoleScoresTableFilterComposer,
          $$HoleScoresTableOrderingComposer,
          $$HoleScoresTableAnnotationComposer,
          $$HoleScoresTableCreateCompanionBuilder,
          $$HoleScoresTableUpdateCompanionBuilder,
          (HoleScore, $$HoleScoresTableReferences),
          HoleScore,
          PrefetchHooks Function({bool roundId, bool groupRoundId})
        > {
  $$HoleScoresTableTableManager(_$AppDatabase db, $HoleScoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HoleScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HoleScoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HoleScoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> roundId = const Value.absent(),
                Value<int> holeNumber = const Value.absent(),
                Value<int> par = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int?> yardage = const Value.absent(),
                Value<int?> putts = const Value.absent(),
                Value<String?> fairwayHit = const Value.absent(),
                Value<int?> penalties = const Value.absent(),
                Value<int?> groupRoundId = const Value.absent(),
              }) => HoleScoresCompanion(
                id: id,
                roundId: roundId,
                holeNumber: holeNumber,
                par: par,
                score: score,
                yardage: yardage,
                putts: putts,
                fairwayHit: fairwayHit,
                penalties: penalties,
                groupRoundId: groupRoundId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int roundId,
                required int holeNumber,
                required int par,
                required int score,
                Value<int?> yardage = const Value.absent(),
                Value<int?> putts = const Value.absent(),
                Value<String?> fairwayHit = const Value.absent(),
                Value<int?> penalties = const Value.absent(),
                Value<int?> groupRoundId = const Value.absent(),
              }) => HoleScoresCompanion.insert(
                id: id,
                roundId: roundId,
                holeNumber: holeNumber,
                par: par,
                score: score,
                yardage: yardage,
                putts: putts,
                fairwayHit: fairwayHit,
                penalties: penalties,
                groupRoundId: groupRoundId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$HoleScoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({roundId = false, groupRoundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (roundId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.roundId,
                                referencedTable: $$HoleScoresTableReferences
                                    ._roundIdTable(db),
                                referencedColumn: $$HoleScoresTableReferences
                                    ._roundIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (groupRoundId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupRoundId,
                                referencedTable: $$HoleScoresTableReferences
                                    ._groupRoundIdTable(db),
                                referencedColumn: $$HoleScoresTableReferences
                                    ._groupRoundIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HoleScoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HoleScoresTable,
      HoleScore,
      $$HoleScoresTableFilterComposer,
      $$HoleScoresTableOrderingComposer,
      $$HoleScoresTableAnnotationComposer,
      $$HoleScoresTableCreateCompanionBuilder,
      $$HoleScoresTableUpdateCompanionBuilder,
      (HoleScore, $$HoleScoresTableReferences),
      HoleScore,
      PrefetchHooks Function({bool roundId, bool groupRoundId})
    >;
typedef $$ClubsTableCreateCompanionBuilder =
    ClubsCompanion Function({
      Value<int> id,
      required String userId,
      required String type,
      Value<String?> brand,
      Value<String?> model,
      Value<double?> loft,
      Value<String?> notes,
      Value<String?> photoUrl,
      Value<String?> firestoreId,
      Value<DateTime> createdAt,
    });
typedef $$ClubsTableUpdateCompanionBuilder =
    ClubsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> type,
      Value<String?> brand,
      Value<String?> model,
      Value<double?> loft,
      Value<String?> notes,
      Value<String?> photoUrl,
      Value<String?> firestoreId,
      Value<DateTime> createdAt,
    });

final class $$ClubsTableReferences
    extends BaseReferences<_$AppDatabase, $ClubsTable, Club> {
  $$ClubsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PracticeShotsTable, List<PracticeShot>>
  _practiceShotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.practiceShots,
    aliasName: $_aliasNameGenerator(db.clubs.id, db.practiceShots.clubId),
  );

  $$PracticeShotsTableProcessedTableManager get practiceShotsRefs {
    final manager = $$PracticeShotsTableTableManager(
      $_db,
      $_db.practiceShots,
    ).filter((f) => f.clubId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_practiceShotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ClubsTableFilterComposer extends Composer<_$AppDatabase, $ClubsTable> {
  $$ClubsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loft => $composableBuilder(
    column: $table.loft,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> practiceShotsRefs(
    Expression<bool> Function($$PracticeShotsTableFilterComposer f) f,
  ) {
    final $$PracticeShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceShots,
      getReferencedColumn: (t) => t.clubId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeShotsTableFilterComposer(
            $db: $db,
            $table: $db.practiceShots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClubsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClubsTable> {
  $$ClubsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loft => $composableBuilder(
    column: $table.loft,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClubsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClubsTable> {
  $$ClubsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<double> get loft =>
      $composableBuilder(column: $table.loft, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> practiceShotsRefs<T extends Object>(
    Expression<T> Function($$PracticeShotsTableAnnotationComposer a) f,
  ) {
    final $$PracticeShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceShots,
      getReferencedColumn: (t) => t.clubId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceShots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ClubsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClubsTable,
          Club,
          $$ClubsTableFilterComposer,
          $$ClubsTableOrderingComposer,
          $$ClubsTableAnnotationComposer,
          $$ClubsTableCreateCompanionBuilder,
          $$ClubsTableUpdateCompanionBuilder,
          (Club, $$ClubsTableReferences),
          Club,
          PrefetchHooks Function({bool practiceShotsRefs})
        > {
  $$ClubsTableTableManager(_$AppDatabase db, $ClubsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClubsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClubsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClubsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<double?> loft = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ClubsCompanion(
                id: id,
                userId: userId,
                type: type,
                brand: brand,
                model: model,
                loft: loft,
                notes: notes,
                photoUrl: photoUrl,
                firestoreId: firestoreId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String type,
                Value<String?> brand = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<double?> loft = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ClubsCompanion.insert(
                id: id,
                userId: userId,
                type: type,
                brand: brand,
                model: model,
                loft: loft,
                notes: notes,
                photoUrl: photoUrl,
                firestoreId: firestoreId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$ClubsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({practiceShotsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (practiceShotsRefs) db.practiceShots,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (practiceShotsRefs)
                    await $_getPrefetchedData<Club, $ClubsTable, PracticeShot>(
                      currentTable: table,
                      referencedTable: $$ClubsTableReferences
                          ._practiceShotsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ClubsTableReferences(
                        db,
                        table,
                        p0,
                      ).practiceShotsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.clubId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ClubsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClubsTable,
      Club,
      $$ClubsTableFilterComposer,
      $$ClubsTableOrderingComposer,
      $$ClubsTableAnnotationComposer,
      $$ClubsTableCreateCompanionBuilder,
      $$ClubsTableUpdateCompanionBuilder,
      (Club, $$ClubsTableReferences),
      Club,
      PrefetchHooks Function({bool practiceShotsRefs})
    >;
typedef $$FriendsTableCreateCompanionBuilder =
    FriendsCompanion Function({
      Value<int> id,
      required String userId,
      required String friendId,
      Value<String?> friendName,
      Value<String?> friendAvatar,
      Value<String?> firestoreId,
      Value<DateTime> addedAt,
    });
typedef $$FriendsTableUpdateCompanionBuilder =
    FriendsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> friendId,
      Value<String?> friendName,
      Value<String?> friendAvatar,
      Value<String?> firestoreId,
      Value<DateTime> addedAt,
    });

class $$FriendsTableFilterComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get friendAvatar => $composableBuilder(
    column: $table.friendAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FriendsTableOrderingComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendId => $composableBuilder(
    column: $table.friendId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get friendAvatar => $composableBuilder(
    column: $table.friendAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FriendsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FriendsTable> {
  $$FriendsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get friendId =>
      $composableBuilder(column: $table.friendId, builder: (column) => column);

  GeneratedColumn<String> get friendName => $composableBuilder(
    column: $table.friendName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get friendAvatar => $composableBuilder(
    column: $table.friendAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FriendsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FriendsTable,
          Friend,
          $$FriendsTableFilterComposer,
          $$FriendsTableOrderingComposer,
          $$FriendsTableAnnotationComposer,
          $$FriendsTableCreateCompanionBuilder,
          $$FriendsTableUpdateCompanionBuilder,
          (Friend, BaseReferences<_$AppDatabase, $FriendsTable, Friend>),
          Friend,
          PrefetchHooks Function()
        > {
  $$FriendsTableTableManager(_$AppDatabase db, $FriendsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FriendsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FriendsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FriendsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> friendId = const Value.absent(),
                Value<String?> friendName = const Value.absent(),
                Value<String?> friendAvatar = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FriendsCompanion(
                id: id,
                userId: userId,
                friendId: friendId,
                friendName: friendName,
                friendAvatar: friendAvatar,
                firestoreId: firestoreId,
                addedAt: addedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String friendId,
                Value<String?> friendName = const Value.absent(),
                Value<String?> friendAvatar = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
              }) => FriendsCompanion.insert(
                id: id,
                userId: userId,
                friendId: friendId,
                friendName: friendName,
                friendAvatar: friendAvatar,
                firestoreId: firestoreId,
                addedAt: addedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FriendsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FriendsTable,
      Friend,
      $$FriendsTableFilterComposer,
      $$FriendsTableOrderingComposer,
      $$FriendsTableAnnotationComposer,
      $$FriendsTableCreateCompanionBuilder,
      $$FriendsTableUpdateCompanionBuilder,
      (Friend, BaseReferences<_$AppDatabase, $FriendsTable, Friend>),
      Friend,
      PrefetchHooks Function()
    >;
typedef $$GroupRoundParticipantsTableCreateCompanionBuilder =
    GroupRoundParticipantsCompanion Function({
      Value<int> id,
      required int groupRoundId,
      required String userId,
      Value<String> status,
      Value<String> role,
      Value<DateTime> joinedAt,
    });
typedef $$GroupRoundParticipantsTableUpdateCompanionBuilder =
    GroupRoundParticipantsCompanion Function({
      Value<int> id,
      Value<int> groupRoundId,
      Value<String> userId,
      Value<String> status,
      Value<String> role,
      Value<DateTime> joinedAt,
    });

final class $$GroupRoundParticipantsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $GroupRoundParticipantsTable,
          GroupRoundParticipant
        > {
  $$GroupRoundParticipantsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupRoundsTable _groupRoundIdTable(_$AppDatabase db) =>
      db.groupRounds.createAlias(
        $_aliasNameGenerator(
          db.groupRoundParticipants.groupRoundId,
          db.groupRounds.id,
        ),
      );

  $$GroupRoundsTableProcessedTableManager get groupRoundId {
    final $_column = $_itemColumn<int>('group_round_id')!;

    final manager = $$GroupRoundsTableTableManager(
      $_db,
      $_db.groupRounds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupRoundIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GroupRoundParticipantsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupRoundParticipantsTable> {
  $$GroupRoundParticipantsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupRoundsTableFilterComposer get groupRoundId {
    final $$GroupRoundsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupRoundId,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableFilterComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupRoundParticipantsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupRoundParticipantsTable> {
  $$GroupRoundParticipantsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupRoundsTableOrderingComposer get groupRoundId {
    final $$GroupRoundsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupRoundId,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableOrderingComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupRoundParticipantsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupRoundParticipantsTable> {
  $$GroupRoundParticipantsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  $$GroupRoundsTableAnnotationComposer get groupRoundId {
    final $$GroupRoundsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupRoundId,
      referencedTable: $db.groupRounds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupRoundsTableAnnotationComposer(
            $db: $db,
            $table: $db.groupRounds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GroupRoundParticipantsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupRoundParticipantsTable,
          GroupRoundParticipant,
          $$GroupRoundParticipantsTableFilterComposer,
          $$GroupRoundParticipantsTableOrderingComposer,
          $$GroupRoundParticipantsTableAnnotationComposer,
          $$GroupRoundParticipantsTableCreateCompanionBuilder,
          $$GroupRoundParticipantsTableUpdateCompanionBuilder,
          (GroupRoundParticipant, $$GroupRoundParticipantsTableReferences),
          GroupRoundParticipant,
          PrefetchHooks Function({bool groupRoundId})
        > {
  $$GroupRoundParticipantsTableTableManager(
    _$AppDatabase db,
    $GroupRoundParticipantsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupRoundParticipantsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$GroupRoundParticipantsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$GroupRoundParticipantsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> groupRoundId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
              }) => GroupRoundParticipantsCompanion(
                id: id,
                groupRoundId: groupRoundId,
                userId: userId,
                status: status,
                role: role,
                joinedAt: joinedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int groupRoundId,
                required String userId,
                Value<String> status = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<DateTime> joinedAt = const Value.absent(),
              }) => GroupRoundParticipantsCompanion.insert(
                id: id,
                groupRoundId: groupRoundId,
                userId: userId,
                status: status,
                role: role,
                joinedAt: joinedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GroupRoundParticipantsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupRoundId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupRoundId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.groupRoundId,
                                referencedTable:
                                    $$GroupRoundParticipantsTableReferences
                                        ._groupRoundIdTable(db),
                                referencedColumn:
                                    $$GroupRoundParticipantsTableReferences
                                        ._groupRoundIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GroupRoundParticipantsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupRoundParticipantsTable,
      GroupRoundParticipant,
      $$GroupRoundParticipantsTableFilterComposer,
      $$GroupRoundParticipantsTableOrderingComposer,
      $$GroupRoundParticipantsTableAnnotationComposer,
      $$GroupRoundParticipantsTableCreateCompanionBuilder,
      $$GroupRoundParticipantsTableUpdateCompanionBuilder,
      (GroupRoundParticipant, $$GroupRoundParticipantsTableReferences),
      GroupRoundParticipant,
      PrefetchHooks Function({bool groupRoundId})
    >;
typedef $$DrillsTableCreateCompanionBuilder =
    DrillsCompanion Function({
      Value<int> id,
      Value<String?> userId,
      required String name,
      required String description,
      Value<String> category,
      required String difficulty,
      required int durationMinutes,
      Value<String> icon,
      Value<bool> isCustom,
      Value<String?> firestoreId,
    });
typedef $$DrillsTableUpdateCompanionBuilder =
    DrillsCompanion Function({
      Value<int> id,
      Value<String?> userId,
      Value<String> name,
      Value<String> description,
      Value<String> category,
      Value<String> difficulty,
      Value<int> durationMinutes,
      Value<String> icon,
      Value<bool> isCustom,
      Value<String?> firestoreId,
    });

final class $$DrillsTableReferences
    extends BaseReferences<_$AppDatabase, $DrillsTable, Drill> {
  $$DrillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PracticeSessionsTable, List<PracticeSession>>
  _practiceSessionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.practiceSessions,
    aliasName: $_aliasNameGenerator(db.drills.id, db.practiceSessions.drillId),
  );

  $$PracticeSessionsTableProcessedTableManager get practiceSessionsRefs {
    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.drillId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _practiceSessionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DrillStepsTable, List<DrillStep>>
  _drillStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.drillSteps,
    aliasName: $_aliasNameGenerator(db.drills.id, db.drillSteps.drillId),
  );

  $$DrillStepsTableProcessedTableManager get drillStepsRefs {
    final manager = $$DrillStepsTableTableManager(
      $_db,
      $_db.drillSteps,
    ).filter((f) => f.drillId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_drillStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DrillsTableFilterComposer
    extends Composer<_$AppDatabase, $DrillsTable> {
  $$DrillsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> practiceSessionsRefs(
    Expression<bool> Function($$PracticeSessionsTableFilterComposer f) f,
  ) {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.drillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> drillStepsRefs(
    Expression<bool> Function($$DrillStepsTableFilterComposer f) f,
  ) {
    final $$DrillStepsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.drillSteps,
      getReferencedColumn: (t) => t.drillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillStepsTableFilterComposer(
            $db: $db,
            $table: $db.drillSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DrillsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrillsTable> {
  $$DrillsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DrillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrillsTable> {
  $$DrillsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMinutes => $composableBuilder(
    column: $table.durationMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  Expression<T> practiceSessionsRefs<T extends Object>(
    Expression<T> Function($$PracticeSessionsTableAnnotationComposer a) f,
  ) {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.drillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> drillStepsRefs<T extends Object>(
    Expression<T> Function($$DrillStepsTableAnnotationComposer a) f,
  ) {
    final $$DrillStepsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.drillSteps,
      getReferencedColumn: (t) => t.drillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillStepsTableAnnotationComposer(
            $db: $db,
            $table: $db.drillSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DrillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrillsTable,
          Drill,
          $$DrillsTableFilterComposer,
          $$DrillsTableOrderingComposer,
          $$DrillsTableAnnotationComposer,
          $$DrillsTableCreateCompanionBuilder,
          $$DrillsTableUpdateCompanionBuilder,
          (Drill, $$DrillsTableReferences),
          Drill,
          PrefetchHooks Function({
            bool practiceSessionsRefs,
            bool drillStepsRefs,
          })
        > {
  $$DrillsTableTableManager(_$AppDatabase db, $DrillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<int> durationMinutes = const Value.absent(),
                Value<String> icon = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
              }) => DrillsCompanion(
                id: id,
                userId: userId,
                name: name,
                description: description,
                category: category,
                difficulty: difficulty,
                durationMinutes: durationMinutes,
                icon: icon,
                isCustom: isCustom,
                firestoreId: firestoreId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                required String name,
                required String description,
                Value<String> category = const Value.absent(),
                required String difficulty,
                required int durationMinutes,
                Value<String> icon = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
              }) => DrillsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                description: description,
                category: category,
                difficulty: difficulty,
                durationMinutes: durationMinutes,
                icon: icon,
                isCustom: isCustom,
                firestoreId: firestoreId,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DrillsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({practiceSessionsRefs = false, drillStepsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (practiceSessionsRefs) db.practiceSessions,
                    if (drillStepsRefs) db.drillSteps,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (practiceSessionsRefs)
                        await $_getPrefetchedData<
                          Drill,
                          $DrillsTable,
                          PracticeSession
                        >(
                          currentTable: table,
                          referencedTable: $$DrillsTableReferences
                              ._practiceSessionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DrillsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceSessionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.drillId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (drillStepsRefs)
                        await $_getPrefetchedData<
                          Drill,
                          $DrillsTable,
                          DrillStep
                        >(
                          currentTable: table,
                          referencedTable: $$DrillsTableReferences
                              ._drillStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$DrillsTableReferences(
                                db,
                                table,
                                p0,
                              ).drillStepsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.drillId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$DrillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrillsTable,
      Drill,
      $$DrillsTableFilterComposer,
      $$DrillsTableOrderingComposer,
      $$DrillsTableAnnotationComposer,
      $$DrillsTableCreateCompanionBuilder,
      $$DrillsTableUpdateCompanionBuilder,
      (Drill, $$DrillsTableReferences),
      Drill,
      PrefetchHooks Function({bool practiceSessionsRefs, bool drillStepsRefs})
    >;
typedef $$PracticeSessionsTableCreateCompanionBuilder =
    PracticeSessionsCompanion Function({
      Value<int> id,
      required String userId,
      Value<String?> firestoreId,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<String?> locationName,
      Value<int> totalBalls,
      Value<String> sessionType,
      Value<int?> drillId,
      Value<int?> targetDistance,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });
typedef $$PracticeSessionsTableUpdateCompanionBuilder =
    PracticeSessionsCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String?> firestoreId,
      Value<DateTime> startTime,
      Value<DateTime?> endTime,
      Value<String?> locationName,
      Value<int> totalBalls,
      Value<String> sessionType,
      Value<int?> drillId,
      Value<int?> targetDistance,
      Value<String?> notes,
      Value<DateTime> createdAt,
    });

final class $$PracticeSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PracticeSessionsTable, PracticeSession> {
  $$PracticeSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $DrillsTable _drillIdTable(_$AppDatabase db) => db.drills.createAlias(
    $_aliasNameGenerator(db.practiceSessions.drillId, db.drills.id),
  );

  $$DrillsTableProcessedTableManager? get drillId {
    final $_column = $_itemColumn<int>('drill_id');
    if ($_column == null) return null;
    final manager = $$DrillsTableTableManager(
      $_db,
      $_db.drills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_drillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PracticeShotsTable, List<PracticeShot>>
  _practiceShotsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.practiceShots,
    aliasName: $_aliasNameGenerator(
      db.practiceSessions.id,
      db.practiceShots.sessionId,
    ),
  );

  $$PracticeShotsTableProcessedTableManager get practiceShotsRefs {
    final manager = $$PracticeShotsTableTableManager(
      $_db,
      $_db.practiceShots,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_practiceShotsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PracticeSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBalls => $composableBuilder(
    column: $table.totalBalls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$DrillsTableFilterComposer get drillId {
    final $$DrillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.drillId,
      referencedTable: $db.drills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillsTableFilterComposer(
            $db: $db,
            $table: $db.drills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> practiceShotsRefs(
    Expression<bool> Function($$PracticeShotsTableFilterComposer f) f,
  ) {
    final $$PracticeShotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceShots,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeShotsTableFilterComposer(
            $db: $db,
            $table: $db.practiceShots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBalls => $composableBuilder(
    column: $table.totalBalls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$DrillsTableOrderingComposer get drillId {
    final $$DrillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.drillId,
      referencedTable: $db.drills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillsTableOrderingComposer(
            $db: $db,
            $table: $db.drills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeSessionsTable> {
  $$PracticeSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBalls => $composableBuilder(
    column: $table.totalBalls,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionType => $composableBuilder(
    column: $table.sessionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$DrillsTableAnnotationComposer get drillId {
    final $$DrillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.drillId,
      referencedTable: $db.drills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillsTableAnnotationComposer(
            $db: $db,
            $table: $db.drills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> practiceShotsRefs<T extends Object>(
    Expression<T> Function($$PracticeShotsTableAnnotationComposer a) f,
  ) {
    final $$PracticeShotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.practiceShots,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeShotsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceShots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PracticeSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PracticeSessionsTable,
          PracticeSession,
          $$PracticeSessionsTableFilterComposer,
          $$PracticeSessionsTableOrderingComposer,
          $$PracticeSessionsTableAnnotationComposer,
          $$PracticeSessionsTableCreateCompanionBuilder,
          $$PracticeSessionsTableUpdateCompanionBuilder,
          (PracticeSession, $$PracticeSessionsTableReferences),
          PracticeSession,
          PrefetchHooks Function({bool drillId, bool practiceShotsRefs})
        > {
  $$PracticeSessionsTableTableManager(
    _$AppDatabase db,
    $PracticeSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<int> totalBalls = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<int?> drillId = const Value.absent(),
                Value<int?> targetDistance = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PracticeSessionsCompanion(
                id: id,
                userId: userId,
                firestoreId: firestoreId,
                startTime: startTime,
                endTime: endTime,
                locationName: locationName,
                totalBalls: totalBalls,
                sessionType: sessionType,
                drillId: drillId,
                targetDistance: targetDistance,
                notes: notes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                Value<String?> firestoreId = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime?> endTime = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<int> totalBalls = const Value.absent(),
                Value<String> sessionType = const Value.absent(),
                Value<int?> drillId = const Value.absent(),
                Value<int?> targetDistance = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PracticeSessionsCompanion.insert(
                id: id,
                userId: userId,
                firestoreId: firestoreId,
                startTime: startTime,
                endTime: endTime,
                locationName: locationName,
                totalBalls: totalBalls,
                sessionType: sessionType,
                drillId: drillId,
                targetDistance: targetDistance,
                notes: notes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({drillId = false, practiceShotsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (practiceShotsRefs) db.practiceShots,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (drillId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.drillId,
                                    referencedTable:
                                        $$PracticeSessionsTableReferences
                                            ._drillIdTable(db),
                                    referencedColumn:
                                        $$PracticeSessionsTableReferences
                                            ._drillIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (practiceShotsRefs)
                        await $_getPrefetchedData<
                          PracticeSession,
                          $PracticeSessionsTable,
                          PracticeShot
                        >(
                          currentTable: table,
                          referencedTable: $$PracticeSessionsTableReferences
                              ._practiceShotsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PracticeSessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).practiceShotsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PracticeSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PracticeSessionsTable,
      PracticeSession,
      $$PracticeSessionsTableFilterComposer,
      $$PracticeSessionsTableOrderingComposer,
      $$PracticeSessionsTableAnnotationComposer,
      $$PracticeSessionsTableCreateCompanionBuilder,
      $$PracticeSessionsTableUpdateCompanionBuilder,
      (PracticeSession, $$PracticeSessionsTableReferences),
      PracticeSession,
      PrefetchHooks Function({bool drillId, bool practiceShotsRefs})
    >;
typedef $$PracticeShotsTableCreateCompanionBuilder =
    PracticeShotsCompanion Function({
      Value<int> id,
      required int sessionId,
      Value<String?> firestoreId,
      required int clubId,
      Value<double?> distance,
      Value<String?> quality,
      Value<String?> shotShape,
      Value<String?> ballFlightJson,
      Value<String?> videoUrl,
      Value<String?> poseMetricsJson,
      Value<DateTime> timestamp,
    });
typedef $$PracticeShotsTableUpdateCompanionBuilder =
    PracticeShotsCompanion Function({
      Value<int> id,
      Value<int> sessionId,
      Value<String?> firestoreId,
      Value<int> clubId,
      Value<double?> distance,
      Value<String?> quality,
      Value<String?> shotShape,
      Value<String?> ballFlightJson,
      Value<String?> videoUrl,
      Value<String?> poseMetricsJson,
      Value<DateTime> timestamp,
    });

final class $$PracticeShotsTableReferences
    extends BaseReferences<_$AppDatabase, $PracticeShotsTable, PracticeShot> {
  $$PracticeShotsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PracticeSessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.practiceSessions.createAlias(
        $_aliasNameGenerator(
          db.practiceShots.sessionId,
          db.practiceSessions.id,
        ),
      );

  $$PracticeSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<int>('session_id')!;

    final manager = $$PracticeSessionsTableTableManager(
      $_db,
      $_db.practiceSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ClubsTable _clubIdTable(_$AppDatabase db) => db.clubs.createAlias(
    $_aliasNameGenerator(db.practiceShots.clubId, db.clubs.id),
  );

  $$ClubsTableProcessedTableManager get clubId {
    final $_column = $_itemColumn<int>('club_id')!;

    final manager = $$ClubsTableTableManager(
      $_db,
      $_db.clubs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clubIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PracticeShotsTableFilterComposer
    extends Composer<_$AppDatabase, $PracticeShotsTable> {
  $$PracticeShotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shotShape => $composableBuilder(
    column: $table.shotShape,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ballFlightJson => $composableBuilder(
    column: $table.ballFlightJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poseMetricsJson => $composableBuilder(
    column: $table.poseMetricsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  $$PracticeSessionsTableFilterComposer get sessionId {
    final $$PracticeSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableFilterComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClubsTableFilterComposer get clubId {
    final $$ClubsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clubId,
      referencedTable: $db.clubs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClubsTableFilterComposer(
            $db: $db,
            $table: $db.clubs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeShotsTableOrderingComposer
    extends Composer<_$AppDatabase, $PracticeShotsTable> {
  $$PracticeShotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get quality => $composableBuilder(
    column: $table.quality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shotShape => $composableBuilder(
    column: $table.shotShape,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ballFlightJson => $composableBuilder(
    column: $table.ballFlightJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoUrl => $composableBuilder(
    column: $table.videoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poseMetricsJson => $composableBuilder(
    column: $table.poseMetricsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  $$PracticeSessionsTableOrderingComposer get sessionId {
    final $$PracticeSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClubsTableOrderingComposer get clubId {
    final $$ClubsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clubId,
      referencedTable: $db.clubs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClubsTableOrderingComposer(
            $db: $db,
            $table: $db.clubs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeShotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PracticeShotsTable> {
  $$PracticeShotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get firestoreId => $composableBuilder(
    column: $table.firestoreId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<String> get quality =>
      $composableBuilder(column: $table.quality, builder: (column) => column);

  GeneratedColumn<String> get shotShape =>
      $composableBuilder(column: $table.shotShape, builder: (column) => column);

  GeneratedColumn<String> get ballFlightJson => $composableBuilder(
    column: $table.ballFlightJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoUrl =>
      $composableBuilder(column: $table.videoUrl, builder: (column) => column);

  GeneratedColumn<String> get poseMetricsJson => $composableBuilder(
    column: $table.poseMetricsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  $$PracticeSessionsTableAnnotationComposer get sessionId {
    final $$PracticeSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.practiceSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PracticeSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.practiceSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ClubsTableAnnotationComposer get clubId {
    final $$ClubsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.clubId,
      referencedTable: $db.clubs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ClubsTableAnnotationComposer(
            $db: $db,
            $table: $db.clubs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PracticeShotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PracticeShotsTable,
          PracticeShot,
          $$PracticeShotsTableFilterComposer,
          $$PracticeShotsTableOrderingComposer,
          $$PracticeShotsTableAnnotationComposer,
          $$PracticeShotsTableCreateCompanionBuilder,
          $$PracticeShotsTableUpdateCompanionBuilder,
          (PracticeShot, $$PracticeShotsTableReferences),
          PracticeShot,
          PrefetchHooks Function({bool sessionId, bool clubId})
        > {
  $$PracticeShotsTableTableManager(_$AppDatabase db, $PracticeShotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PracticeShotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PracticeShotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PracticeShotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> sessionId = const Value.absent(),
                Value<String?> firestoreId = const Value.absent(),
                Value<int> clubId = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<String?> shotShape = const Value.absent(),
                Value<String?> ballFlightJson = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> poseMetricsJson = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => PracticeShotsCompanion(
                id: id,
                sessionId: sessionId,
                firestoreId: firestoreId,
                clubId: clubId,
                distance: distance,
                quality: quality,
                shotShape: shotShape,
                ballFlightJson: ballFlightJson,
                videoUrl: videoUrl,
                poseMetricsJson: poseMetricsJson,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int sessionId,
                Value<String?> firestoreId = const Value.absent(),
                required int clubId,
                Value<double?> distance = const Value.absent(),
                Value<String?> quality = const Value.absent(),
                Value<String?> shotShape = const Value.absent(),
                Value<String?> ballFlightJson = const Value.absent(),
                Value<String?> videoUrl = const Value.absent(),
                Value<String?> poseMetricsJson = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => PracticeShotsCompanion.insert(
                id: id,
                sessionId: sessionId,
                firestoreId: firestoreId,
                clubId: clubId,
                distance: distance,
                quality: quality,
                shotShape: shotShape,
                ballFlightJson: ballFlightJson,
                videoUrl: videoUrl,
                poseMetricsJson: poseMetricsJson,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PracticeShotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, clubId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.sessionId,
                                referencedTable: $$PracticeShotsTableReferences
                                    ._sessionIdTable(db),
                                referencedColumn: $$PracticeShotsTableReferences
                                    ._sessionIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (clubId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.clubId,
                                referencedTable: $$PracticeShotsTableReferences
                                    ._clubIdTable(db),
                                referencedColumn: $$PracticeShotsTableReferences
                                    ._clubIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PracticeShotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PracticeShotsTable,
      PracticeShot,
      $$PracticeShotsTableFilterComposer,
      $$PracticeShotsTableOrderingComposer,
      $$PracticeShotsTableAnnotationComposer,
      $$PracticeShotsTableCreateCompanionBuilder,
      $$PracticeShotsTableUpdateCompanionBuilder,
      (PracticeShot, $$PracticeShotsTableReferences),
      PracticeShot,
      PrefetchHooks Function({bool sessionId, bool clubId})
    >;
typedef $$DrillStepsTableCreateCompanionBuilder =
    DrillStepsCompanion Function({
      Value<int> id,
      required int drillId,
      required int stepOrder,
      required String instruction,
      Value<int?> targetDistance,
      required int ballsRequired,
      Value<String?> clubType,
    });
typedef $$DrillStepsTableUpdateCompanionBuilder =
    DrillStepsCompanion Function({
      Value<int> id,
      Value<int> drillId,
      Value<int> stepOrder,
      Value<String> instruction,
      Value<int?> targetDistance,
      Value<int> ballsRequired,
      Value<String?> clubType,
    });

final class $$DrillStepsTableReferences
    extends BaseReferences<_$AppDatabase, $DrillStepsTable, DrillStep> {
  $$DrillStepsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DrillsTable _drillIdTable(_$AppDatabase db) => db.drills.createAlias(
    $_aliasNameGenerator(db.drillSteps.drillId, db.drills.id),
  );

  $$DrillsTableProcessedTableManager get drillId {
    final $_column = $_itemColumn<int>('drill_id')!;

    final manager = $$DrillsTableTableManager(
      $_db,
      $_db.drills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_drillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DrillStepsTableFilterComposer
    extends Composer<_$AppDatabase, $DrillStepsTable> {
  $$DrillStepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepOrder => $composableBuilder(
    column: $table.stepOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instruction => $composableBuilder(
    column: $table.instruction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ballsRequired => $composableBuilder(
    column: $table.ballsRequired,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clubType => $composableBuilder(
    column: $table.clubType,
    builder: (column) => ColumnFilters(column),
  );

  $$DrillsTableFilterComposer get drillId {
    final $$DrillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.drillId,
      referencedTable: $db.drills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillsTableFilterComposer(
            $db: $db,
            $table: $db.drills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DrillStepsTableOrderingComposer
    extends Composer<_$AppDatabase, $DrillStepsTable> {
  $$DrillStepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepOrder => $composableBuilder(
    column: $table.stepOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instruction => $composableBuilder(
    column: $table.instruction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ballsRequired => $composableBuilder(
    column: $table.ballsRequired,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clubType => $composableBuilder(
    column: $table.clubType,
    builder: (column) => ColumnOrderings(column),
  );

  $$DrillsTableOrderingComposer get drillId {
    final $$DrillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.drillId,
      referencedTable: $db.drills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillsTableOrderingComposer(
            $db: $db,
            $table: $db.drills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DrillStepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DrillStepsTable> {
  $$DrillStepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get stepOrder =>
      $composableBuilder(column: $table.stepOrder, builder: (column) => column);

  GeneratedColumn<String> get instruction => $composableBuilder(
    column: $table.instruction,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetDistance => $composableBuilder(
    column: $table.targetDistance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get ballsRequired => $composableBuilder(
    column: $table.ballsRequired,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clubType =>
      $composableBuilder(column: $table.clubType, builder: (column) => column);

  $$DrillsTableAnnotationComposer get drillId {
    final $$DrillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.drillId,
      referencedTable: $db.drills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DrillsTableAnnotationComposer(
            $db: $db,
            $table: $db.drills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DrillStepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DrillStepsTable,
          DrillStep,
          $$DrillStepsTableFilterComposer,
          $$DrillStepsTableOrderingComposer,
          $$DrillStepsTableAnnotationComposer,
          $$DrillStepsTableCreateCompanionBuilder,
          $$DrillStepsTableUpdateCompanionBuilder,
          (DrillStep, $$DrillStepsTableReferences),
          DrillStep,
          PrefetchHooks Function({bool drillId})
        > {
  $$DrillStepsTableTableManager(_$AppDatabase db, $DrillStepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DrillStepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DrillStepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DrillStepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> drillId = const Value.absent(),
                Value<int> stepOrder = const Value.absent(),
                Value<String> instruction = const Value.absent(),
                Value<int?> targetDistance = const Value.absent(),
                Value<int> ballsRequired = const Value.absent(),
                Value<String?> clubType = const Value.absent(),
              }) => DrillStepsCompanion(
                id: id,
                drillId: drillId,
                stepOrder: stepOrder,
                instruction: instruction,
                targetDistance: targetDistance,
                ballsRequired: ballsRequired,
                clubType: clubType,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int drillId,
                required int stepOrder,
                required String instruction,
                Value<int?> targetDistance = const Value.absent(),
                required int ballsRequired,
                Value<String?> clubType = const Value.absent(),
              }) => DrillStepsCompanion.insert(
                id: id,
                drillId: drillId,
                stepOrder: stepOrder,
                instruction: instruction,
                targetDistance: targetDistance,
                ballsRequired: ballsRequired,
                clubType: clubType,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DrillStepsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({drillId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (drillId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.drillId,
                                referencedTable: $$DrillStepsTableReferences
                                    ._drillIdTable(db),
                                referencedColumn: $$DrillStepsTableReferences
                                    ._drillIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DrillStepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DrillStepsTable,
      DrillStep,
      $$DrillStepsTableFilterComposer,
      $$DrillStepsTableOrderingComposer,
      $$DrillStepsTableAnnotationComposer,
      $$DrillStepsTableCreateCompanionBuilder,
      $$DrillStepsTableUpdateCompanionBuilder,
      (DrillStep, $$DrillStepsTableReferences),
      DrillStep,
      PrefetchHooks Function({bool drillId})
    >;
typedef $$ProvidersTableCreateCompanionBuilder =
    ProvidersCompanion Function({
      Value<int> id,
      required String userId,
      required String role,
      required String name,
      required String phone,
      Value<String?> whatsapp,
      Value<int> experience,
      Value<String> coursesJson,
      Value<String?> specializationsJson,
      Value<String> availabilityJson,
      Value<double?> price,
      Value<double> rating,
      Value<int> totalReviews,
      Value<int> totalBookings,
      Value<int> totalCalls,
      Value<bool> isAvailable,
      Value<bool> profileComplete,
      Value<String?> certificationUrl,
      Value<String?> bio,
      Value<String?> personalityType,
      Value<String?> coachingLocation,
      Value<String?> coachingStylesJson,
      Value<String?> sessionTypesJson,
      Value<bool> hasCertification,
      Value<String?> certificationName,
      Value<int> views,
      Value<int> streak,
      Value<DateTime> createdAt,
    });
typedef $$ProvidersTableUpdateCompanionBuilder =
    ProvidersCompanion Function({
      Value<int> id,
      Value<String> userId,
      Value<String> role,
      Value<String> name,
      Value<String> phone,
      Value<String?> whatsapp,
      Value<int> experience,
      Value<String> coursesJson,
      Value<String?> specializationsJson,
      Value<String> availabilityJson,
      Value<double?> price,
      Value<double> rating,
      Value<int> totalReviews,
      Value<int> totalBookings,
      Value<int> totalCalls,
      Value<bool> isAvailable,
      Value<bool> profileComplete,
      Value<String?> certificationUrl,
      Value<String?> bio,
      Value<String?> personalityType,
      Value<String?> coachingLocation,
      Value<String?> coachingStylesJson,
      Value<String?> sessionTypesJson,
      Value<bool> hasCertification,
      Value<String?> certificationName,
      Value<int> views,
      Value<int> streak,
      Value<DateTime> createdAt,
    });

class $$ProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coursesJson => $composableBuilder(
    column: $table.coursesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specializationsJson => $composableBuilder(
    column: $table.specializationsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get availabilityJson => $composableBuilder(
    column: $table.availabilityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBookings => $composableBuilder(
    column: $table.totalBookings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCalls => $composableBuilder(
    column: $table.totalCalls,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get profileComplete => $composableBuilder(
    column: $table.profileComplete,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificationUrl => $composableBuilder(
    column: $table.certificationUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get personalityType => $composableBuilder(
    column: $table.personalityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coachingLocation => $composableBuilder(
    column: $table.coachingLocation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coachingStylesJson => $composableBuilder(
    column: $table.coachingStylesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionTypesJson => $composableBuilder(
    column: $table.sessionTypesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasCertification => $composableBuilder(
    column: $table.hasCertification,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get certificationName => $composableBuilder(
    column: $table.certificationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get views => $composableBuilder(
    column: $table.views,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get whatsapp => $composableBuilder(
    column: $table.whatsapp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coursesJson => $composableBuilder(
    column: $table.coursesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specializationsJson => $composableBuilder(
    column: $table.specializationsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get availabilityJson => $composableBuilder(
    column: $table.availabilityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get price => $composableBuilder(
    column: $table.price,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBookings => $composableBuilder(
    column: $table.totalBookings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCalls => $composableBuilder(
    column: $table.totalCalls,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get profileComplete => $composableBuilder(
    column: $table.profileComplete,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificationUrl => $composableBuilder(
    column: $table.certificationUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get personalityType => $composableBuilder(
    column: $table.personalityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coachingLocation => $composableBuilder(
    column: $table.coachingLocation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coachingStylesJson => $composableBuilder(
    column: $table.coachingStylesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionTypesJson => $composableBuilder(
    column: $table.sessionTypesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCertification => $composableBuilder(
    column: $table.hasCertification,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get certificationName => $composableBuilder(
    column: $table.certificationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get views => $composableBuilder(
    column: $table.views,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streak => $composableBuilder(
    column: $table.streak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get whatsapp =>
      $composableBuilder(column: $table.whatsapp, builder: (column) => column);

  GeneratedColumn<int> get experience => $composableBuilder(
    column: $table.experience,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coursesJson => $composableBuilder(
    column: $table.coursesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specializationsJson => $composableBuilder(
    column: $table.specializationsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get availabilityJson => $composableBuilder(
    column: $table.availabilityJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get price =>
      $composableBuilder(column: $table.price, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get totalReviews => $composableBuilder(
    column: $table.totalReviews,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBookings => $composableBuilder(
    column: $table.totalBookings,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCalls => $composableBuilder(
    column: $table.totalCalls,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAvailable => $composableBuilder(
    column: $table.isAvailable,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get profileComplete => $composableBuilder(
    column: $table.profileComplete,
    builder: (column) => column,
  );

  GeneratedColumn<String> get certificationUrl => $composableBuilder(
    column: $table.certificationUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get personalityType => $composableBuilder(
    column: $table.personalityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coachingLocation => $composableBuilder(
    column: $table.coachingLocation,
    builder: (column) => column,
  );

  GeneratedColumn<String> get coachingStylesJson => $composableBuilder(
    column: $table.coachingStylesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sessionTypesJson => $composableBuilder(
    column: $table.sessionTypesJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasCertification => $composableBuilder(
    column: $table.hasCertification,
    builder: (column) => column,
  );

  GeneratedColumn<String> get certificationName => $composableBuilder(
    column: $table.certificationName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get views =>
      $composableBuilder(column: $table.views, builder: (column) => column);

  GeneratedColumn<int> get streak =>
      $composableBuilder(column: $table.streak, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProvidersTable,
          Provider,
          $$ProvidersTableFilterComposer,
          $$ProvidersTableOrderingComposer,
          $$ProvidersTableAnnotationComposer,
          $$ProvidersTableCreateCompanionBuilder,
          $$ProvidersTableUpdateCompanionBuilder,
          (Provider, BaseReferences<_$AppDatabase, $ProvidersTable, Provider>),
          Provider,
          PrefetchHooks Function()
        > {
  $$ProvidersTableTableManager(_$AppDatabase db, $ProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String?> whatsapp = const Value.absent(),
                Value<int> experience = const Value.absent(),
                Value<String> coursesJson = const Value.absent(),
                Value<String?> specializationsJson = const Value.absent(),
                Value<String> availabilityJson = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> totalReviews = const Value.absent(),
                Value<int> totalBookings = const Value.absent(),
                Value<int> totalCalls = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<bool> profileComplete = const Value.absent(),
                Value<String?> certificationUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> personalityType = const Value.absent(),
                Value<String?> coachingLocation = const Value.absent(),
                Value<String?> coachingStylesJson = const Value.absent(),
                Value<String?> sessionTypesJson = const Value.absent(),
                Value<bool> hasCertification = const Value.absent(),
                Value<String?> certificationName = const Value.absent(),
                Value<int> views = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProvidersCompanion(
                id: id,
                userId: userId,
                role: role,
                name: name,
                phone: phone,
                whatsapp: whatsapp,
                experience: experience,
                coursesJson: coursesJson,
                specializationsJson: specializationsJson,
                availabilityJson: availabilityJson,
                price: price,
                rating: rating,
                totalReviews: totalReviews,
                totalBookings: totalBookings,
                totalCalls: totalCalls,
                isAvailable: isAvailable,
                profileComplete: profileComplete,
                certificationUrl: certificationUrl,
                bio: bio,
                personalityType: personalityType,
                coachingLocation: coachingLocation,
                coachingStylesJson: coachingStylesJson,
                sessionTypesJson: sessionTypesJson,
                hasCertification: hasCertification,
                certificationName: certificationName,
                views: views,
                streak: streak,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String userId,
                required String role,
                required String name,
                required String phone,
                Value<String?> whatsapp = const Value.absent(),
                Value<int> experience = const Value.absent(),
                Value<String> coursesJson = const Value.absent(),
                Value<String?> specializationsJson = const Value.absent(),
                Value<String> availabilityJson = const Value.absent(),
                Value<double?> price = const Value.absent(),
                Value<double> rating = const Value.absent(),
                Value<int> totalReviews = const Value.absent(),
                Value<int> totalBookings = const Value.absent(),
                Value<int> totalCalls = const Value.absent(),
                Value<bool> isAvailable = const Value.absent(),
                Value<bool> profileComplete = const Value.absent(),
                Value<String?> certificationUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> personalityType = const Value.absent(),
                Value<String?> coachingLocation = const Value.absent(),
                Value<String?> coachingStylesJson = const Value.absent(),
                Value<String?> sessionTypesJson = const Value.absent(),
                Value<bool> hasCertification = const Value.absent(),
                Value<String?> certificationName = const Value.absent(),
                Value<int> views = const Value.absent(),
                Value<int> streak = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProvidersCompanion.insert(
                id: id,
                userId: userId,
                role: role,
                name: name,
                phone: phone,
                whatsapp: whatsapp,
                experience: experience,
                coursesJson: coursesJson,
                specializationsJson: specializationsJson,
                availabilityJson: availabilityJson,
                price: price,
                rating: rating,
                totalReviews: totalReviews,
                totalBookings: totalBookings,
                totalCalls: totalCalls,
                isAvailable: isAvailable,
                profileComplete: profileComplete,
                certificationUrl: certificationUrl,
                bio: bio,
                personalityType: personalityType,
                coachingLocation: coachingLocation,
                coachingStylesJson: coachingStylesJson,
                sessionTypesJson: sessionTypesJson,
                hasCertification: hasCertification,
                certificationName: certificationName,
                views: views,
                streak: streak,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProvidersTable,
      Provider,
      $$ProvidersTableFilterComposer,
      $$ProvidersTableOrderingComposer,
      $$ProvidersTableAnnotationComposer,
      $$ProvidersTableCreateCompanionBuilder,
      $$ProvidersTableUpdateCompanionBuilder,
      (Provider, BaseReferences<_$AppDatabase, $ProvidersTable, Provider>),
      Provider,
      PrefetchHooks Function()
    >;
typedef $$InteractionsTableCreateCompanionBuilder =
    InteractionsCompanion Function({
      Value<int> id,
      required String playerId,
      required String providerId,
      required String type,
      Value<String> status,
      Value<DateTime?> lastPromptedAt,
      Value<DateTime> timestamp,
    });
typedef $$InteractionsTableUpdateCompanionBuilder =
    InteractionsCompanion Function({
      Value<int> id,
      Value<String> playerId,
      Value<String> providerId,
      Value<String> type,
      Value<String> status,
      Value<DateTime?> lastPromptedAt,
      Value<DateTime> timestamp,
    });

class $$InteractionsTableFilterComposer
    extends Composer<_$AppDatabase, $InteractionsTable> {
  $$InteractionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPromptedAt => $composableBuilder(
    column: $table.lastPromptedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InteractionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InteractionsTable> {
  $$InteractionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPromptedAt => $composableBuilder(
    column: $table.lastPromptedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InteractionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InteractionsTable> {
  $$InteractionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPromptedAt => $composableBuilder(
    column: $table.lastPromptedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);
}

class $$InteractionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InteractionsTable,
          Interaction,
          $$InteractionsTableFilterComposer,
          $$InteractionsTableOrderingComposer,
          $$InteractionsTableAnnotationComposer,
          $$InteractionsTableCreateCompanionBuilder,
          $$InteractionsTableUpdateCompanionBuilder,
          (
            Interaction,
            BaseReferences<_$AppDatabase, $InteractionsTable, Interaction>,
          ),
          Interaction,
          PrefetchHooks Function()
        > {
  $$InteractionsTableTableManager(_$AppDatabase db, $InteractionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InteractionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InteractionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InteractionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastPromptedAt = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => InteractionsCompanion(
                id: id,
                playerId: playerId,
                providerId: providerId,
                type: type,
                status: status,
                lastPromptedAt: lastPromptedAt,
                timestamp: timestamp,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String playerId,
                required String providerId,
                required String type,
                Value<String> status = const Value.absent(),
                Value<DateTime?> lastPromptedAt = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
              }) => InteractionsCompanion.insert(
                id: id,
                playerId: playerId,
                providerId: providerId,
                type: type,
                status: status,
                lastPromptedAt: lastPromptedAt,
                timestamp: timestamp,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InteractionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InteractionsTable,
      Interaction,
      $$InteractionsTableFilterComposer,
      $$InteractionsTableOrderingComposer,
      $$InteractionsTableAnnotationComposer,
      $$InteractionsTableCreateCompanionBuilder,
      $$InteractionsTableUpdateCompanionBuilder,
      (
        Interaction,
        BaseReferences<_$AppDatabase, $InteractionsTable, Interaction>,
      ),
      Interaction,
      PrefetchHooks Function()
    >;
typedef $$ReviewsTableCreateCompanionBuilder =
    ReviewsCompanion Function({
      Value<int> id,
      required String providerId,
      required String playerId,
      required String playerName,
      Value<String?> playerAvatar,
      required int rating,
      required String comment,
      Value<DateTime> createdAt,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<int> id,
      Value<String> providerId,
      Value<String> playerId,
      Value<String> playerName,
      Value<String?> playerAvatar,
      Value<int> rating,
      Value<String> comment,
      Value<DateTime> createdAt,
    });

class $$ReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerName => $composableBuilder(
    column: $table.playerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playerAvatar => $composableBuilder(
    column: $table.playerAvatar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerId => $composableBuilder(
    column: $table.playerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerName => $composableBuilder(
    column: $table.playerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playerAvatar => $composableBuilder(
    column: $table.playerAvatar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get comment => $composableBuilder(
    column: $table.comment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerId =>
      $composableBuilder(column: $table.playerId, builder: (column) => column);

  GeneratedColumn<String> get playerName => $composableBuilder(
    column: $table.playerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get playerAvatar => $composableBuilder(
    column: $table.playerAvatar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get comment =>
      $composableBuilder(column: $table.comment, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewsTable,
          Review,
          $$ReviewsTableFilterComposer,
          $$ReviewsTableOrderingComposer,
          $$ReviewsTableAnnotationComposer,
          $$ReviewsTableCreateCompanionBuilder,
          $$ReviewsTableUpdateCompanionBuilder,
          (Review, BaseReferences<_$AppDatabase, $ReviewsTable, Review>),
          Review,
          PrefetchHooks Function()
        > {
  $$ReviewsTableTableManager(_$AppDatabase db, $ReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> playerId = const Value.absent(),
                Value<String> playerName = const Value.absent(),
                Value<String?> playerAvatar = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<String> comment = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                providerId: providerId,
                playerId: playerId,
                playerName: playerName,
                playerAvatar: playerAvatar,
                rating: rating,
                comment: comment,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String providerId,
                required String playerId,
                required String playerName,
                Value<String?> playerAvatar = const Value.absent(),
                required int rating,
                required String comment,
                Value<DateTime> createdAt = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                providerId: providerId,
                playerId: playerId,
                playerName: playerName,
                playerAvatar: playerAvatar,
                rating: rating,
                comment: comment,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewsTable,
      Review,
      $$ReviewsTableFilterComposer,
      $$ReviewsTableOrderingComposer,
      $$ReviewsTableAnnotationComposer,
      $$ReviewsTableCreateCompanionBuilder,
      $$ReviewsTableUpdateCompanionBuilder,
      (Review, BaseReferences<_$AppDatabase, $ReviewsTable, Review>),
      Review,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserProfilesTableTableManager get userProfiles =>
      $$UserProfilesTableTableManager(_db, _db.userProfiles);
  $$CoursesTableTableManager get courses =>
      $$CoursesTableTableManager(_db, _db.courses);
  $$RoundsTableTableManager get rounds =>
      $$RoundsTableTableManager(_db, _db.rounds);
  $$GroupRoundsTableTableManager get groupRounds =>
      $$GroupRoundsTableTableManager(_db, _db.groupRounds);
  $$HoleScoresTableTableManager get holeScores =>
      $$HoleScoresTableTableManager(_db, _db.holeScores);
  $$ClubsTableTableManager get clubs =>
      $$ClubsTableTableManager(_db, _db.clubs);
  $$FriendsTableTableManager get friends =>
      $$FriendsTableTableManager(_db, _db.friends);
  $$GroupRoundParticipantsTableTableManager get groupRoundParticipants =>
      $$GroupRoundParticipantsTableTableManager(
        _db,
        _db.groupRoundParticipants,
      );
  $$DrillsTableTableManager get drills =>
      $$DrillsTableTableManager(_db, _db.drills);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(_db, _db.practiceSessions);
  $$PracticeShotsTableTableManager get practiceShots =>
      $$PracticeShotsTableTableManager(_db, _db.practiceShots);
  $$DrillStepsTableTableManager get drillSteps =>
      $$DrillStepsTableTableManager(_db, _db.drillSteps);
  $$ProvidersTableTableManager get providers =>
      $$ProvidersTableTableManager(_db, _db.providers);
  $$InteractionsTableTableManager get interactions =>
      $$InteractionsTableTableManager(_db, _db.interactions);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db, _db.reviews);
}
