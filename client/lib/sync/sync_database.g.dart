// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_database.dart';

// ignore_for_file: type=lint
class $PendingSyncEventsTable extends PendingSyncEvents
    with TableInfo<$PendingSyncEventsTable, PendingSyncEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncEventsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _childIdMeta = const VerificationMeta(
    'childId',
  );
  @override
  late final GeneratedColumn<int> childId = GeneratedColumn<int>(
    'child_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activityIdMeta = const VerificationMeta(
    'activityId',
  );
  @override
  late final GeneratedColumn<String> activityId = GeneratedColumn<String>(
    'activity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
  static const VerificationMeta _starsMeta = const VerificationMeta('stars');
  @override
  late final GeneratedColumn<int> stars = GeneratedColumn<int>(
    'stars',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(SyncStatus.pending),
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<int> nextAttemptAt = GeneratedColumn<int>(
    'next_attempt_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    childId,
    activityId,
    score,
    stars,
    metadata,
    updatedAt,
    deletedAt,
    status,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    syncedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingSyncEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('child_id')) {
      context.handle(
        _childIdMeta,
        childId.isAcceptableOrUnknown(data['child_id']!, _childIdMeta),
      );
    } else if (isInserting) {
      context.missing(_childIdMeta);
    }
    if (data.containsKey('activity_id')) {
      context.handle(
        _activityIdMeta,
        activityId.isAcceptableOrUnknown(data['activity_id']!, _activityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_activityIdMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('stars')) {
      context.handle(
        _starsMeta,
        stars.isAcceptableOrUnknown(data['stars']!, _starsMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      childId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}child_id'],
      )!,
      activityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}activity_id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      stars: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stars'],
      ),
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  $PendingSyncEventsTable createAlias(String alias) {
    return $PendingSyncEventsTable(attachedDatabase, alias);
  }
}

class PendingSyncEvent extends DataClass
    implements Insertable<PendingSyncEvent> {
  final int id;
  final int childId;
  final String activityId;
  final int score;
  final int? stars;

  /// JSON serializado (objeto) o null.
  final String? metadata;

  /// ISO 8601 UTC — clave de resolución LWW en el servidor.
  final String updatedAt;

  /// ISO 8601 UTC o null — soft delete.
  final String? deletedAt;
  final String status;
  final int attempts;

  /// Epoch ms: el evento no se envía antes de este instante (backoff).
  final int nextAttemptAt;
  final String? lastError;

  /// Epoch ms.
  final int createdAt;

  /// Epoch ms o null.
  final int? syncedAt;
  const PendingSyncEvent({
    required this.id,
    required this.childId,
    required this.activityId,
    required this.score,
    this.stars,
    this.metadata,
    required this.updatedAt,
    this.deletedAt,
    required this.status,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
    required this.createdAt,
    this.syncedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['child_id'] = Variable<int>(childId);
    map['activity_id'] = Variable<String>(activityId);
    map['score'] = Variable<int>(score);
    if (!nullToAbsent || stars != null) {
      map['stars'] = Variable<int>(stars);
    }
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    map['status'] = Variable<String>(status);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<int>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    return map;
  }

  PendingSyncEventsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncEventsCompanion(
      id: Value(id),
      childId: Value(childId),
      activityId: Value(activityId),
      score: Value(score),
      stars: stars == null && nullToAbsent
          ? const Value.absent()
          : Value(stars),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      status: Value(status),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory PendingSyncEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncEvent(
      id: serializer.fromJson<int>(json['id']),
      childId: serializer.fromJson<int>(json['childId']),
      activityId: serializer.fromJson<String>(json['activityId']),
      score: serializer.fromJson<int>(json['score']),
      stars: serializer.fromJson<int?>(json['stars']),
      metadata: serializer.fromJson<String?>(json['metadata']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
      status: serializer.fromJson<String>(json['status']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<int>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      syncedAt: serializer.fromJson<int?>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'childId': serializer.toJson<int>(childId),
      'activityId': serializer.toJson<String>(activityId),
      'score': serializer.toJson<int>(score),
      'stars': serializer.toJson<int?>(stars),
      'metadata': serializer.toJson<String?>(metadata),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
      'status': serializer.toJson<String>(status),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<int>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<int>(createdAt),
      'syncedAt': serializer.toJson<int?>(syncedAt),
    };
  }

  PendingSyncEvent copyWith({
    int? id,
    int? childId,
    String? activityId,
    int? score,
    Value<int?> stars = const Value.absent(),
    Value<String?> metadata = const Value.absent(),
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    String? status,
    int? attempts,
    int? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    Value<int?> syncedAt = const Value.absent(),
  }) => PendingSyncEvent(
    id: id ?? this.id,
    childId: childId ?? this.childId,
    activityId: activityId ?? this.activityId,
    score: score ?? this.score,
    stars: stars.present ? stars.value : this.stars,
    metadata: metadata.present ? metadata.value : this.metadata,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    status: status ?? this.status,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  PendingSyncEvent copyWithCompanion(PendingSyncEventsCompanion data) {
    return PendingSyncEvent(
      id: data.id.present ? data.id.value : this.id,
      childId: data.childId.present ? data.childId.value : this.childId,
      activityId: data.activityId.present
          ? data.activityId.value
          : this.activityId,
      score: data.score.present ? data.score.value : this.score,
      stars: data.stars.present ? data.stars.value : this.stars,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      status: data.status.present ? data.status.value : this.status,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncEvent(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('activityId: $activityId, ')
          ..write('score: $score, ')
          ..write('stars: $stars, ')
          ..write('metadata: $metadata, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    childId,
    activityId,
    score,
    stars,
    metadata,
    updatedAt,
    deletedAt,
    status,
    attempts,
    nextAttemptAt,
    lastError,
    createdAt,
    syncedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncEvent &&
          other.id == this.id &&
          other.childId == this.childId &&
          other.activityId == this.activityId &&
          other.score == this.score &&
          other.stars == this.stars &&
          other.metadata == this.metadata &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.status == this.status &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.syncedAt == this.syncedAt);
}

class PendingSyncEventsCompanion extends UpdateCompanion<PendingSyncEvent> {
  final Value<int> id;
  final Value<int> childId;
  final Value<String> activityId;
  final Value<int> score;
  final Value<int?> stars;
  final Value<String?> metadata;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String> status;
  final Value<int> attempts;
  final Value<int> nextAttemptAt;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<int?> syncedAt;
  const PendingSyncEventsCompanion({
    this.id = const Value.absent(),
    this.childId = const Value.absent(),
    this.activityId = const Value.absent(),
    this.score = const Value.absent(),
    this.stars = const Value.absent(),
    this.metadata = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
  });
  PendingSyncEventsCompanion.insert({
    this.id = const Value.absent(),
    required int childId,
    required String activityId,
    required int score,
    this.stars = const Value.absent(),
    this.metadata = const Value.absent(),
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAt,
    this.syncedAt = const Value.absent(),
  }) : childId = Value(childId),
       activityId = Value(activityId),
       score = Value(score),
       updatedAt = Value(updatedAt),
       createdAt = Value(createdAt);
  static Insertable<PendingSyncEvent> custom({
    Expression<int>? id,
    Expression<int>? childId,
    Expression<String>? activityId,
    Expression<int>? score,
    Expression<int>? stars,
    Expression<String>? metadata,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? status,
    Expression<int>? attempts,
    Expression<int>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? syncedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (childId != null) 'child_id': childId,
      if (activityId != null) 'activity_id': activityId,
      if (score != null) 'score': score,
      if (stars != null) 'stars': stars,
      if (metadata != null) 'metadata': metadata,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (status != null) 'status': status,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (syncedAt != null) 'synced_at': syncedAt,
    });
  }

  PendingSyncEventsCompanion copyWith({
    Value<int>? id,
    Value<int>? childId,
    Value<String>? activityId,
    Value<int>? score,
    Value<int?>? stars,
    Value<String?>? metadata,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String>? status,
    Value<int>? attempts,
    Value<int>? nextAttemptAt,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<int?>? syncedAt,
  }) {
    return PendingSyncEventsCompanion(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      activityId: activityId ?? this.activityId,
      score: score ?? this.score,
      stars: stars ?? this.stars,
      metadata: metadata ?? this.metadata,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      syncedAt: syncedAt ?? this.syncedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (childId.present) {
      map['child_id'] = Variable<int>(childId.value);
    }
    if (activityId.present) {
      map['activity_id'] = Variable<String>(activityId.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (stars.present) {
      map['stars'] = Variable<int>(stars.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<int>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncEventsCompanion(')
          ..write('id: $id, ')
          ..write('childId: $childId, ')
          ..write('activityId: $activityId, ')
          ..write('score: $score, ')
          ..write('stars: $stars, ')
          ..write('metadata: $metadata, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('status: $status, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SyncDatabase extends GeneratedDatabase {
  _$SyncDatabase(QueryExecutor e) : super(e);
  $SyncDatabaseManager get managers => $SyncDatabaseManager(this);
  late final $PendingSyncEventsTable pendingSyncEvents =
      $PendingSyncEventsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [pendingSyncEvents];
}

typedef $$PendingSyncEventsTableCreateCompanionBuilder =
    PendingSyncEventsCompanion Function({
      Value<int> id,
      required int childId,
      required String activityId,
      required int score,
      Value<int?> stars,
      Value<String?> metadata,
      required String updatedAt,
      Value<String?> deletedAt,
      Value<String> status,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      required int createdAt,
      Value<int?> syncedAt,
    });
typedef $$PendingSyncEventsTableUpdateCompanionBuilder =
    PendingSyncEventsCompanion Function({
      Value<int> id,
      Value<int> childId,
      Value<String> activityId,
      Value<int> score,
      Value<int?> stars,
      Value<String?> metadata,
      Value<String> updatedAt,
      Value<String?> deletedAt,
      Value<String> status,
      Value<int> attempts,
      Value<int> nextAttemptAt,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<int?> syncedAt,
    });

class $$PendingSyncEventsTableFilterComposer
    extends Composer<_$SyncDatabase, $PendingSyncEventsTable> {
  $$PendingSyncEventsTableFilterComposer({
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

  ColumnFilters<int> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingSyncEventsTableOrderingComposer
    extends Composer<_$SyncDatabase, $PendingSyncEventsTable> {
  $$PendingSyncEventsTableOrderingComposer({
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

  ColumnOrderings<int> get childId => $composableBuilder(
    column: $table.childId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stars => $composableBuilder(
    column: $table.stars,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingSyncEventsTableAnnotationComposer
    extends Composer<_$SyncDatabase, $PendingSyncEventsTable> {
  $$PendingSyncEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get childId =>
      $composableBuilder(column: $table.childId, builder: (column) => column);

  GeneratedColumn<String> get activityId => $composableBuilder(
    column: $table.activityId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get stars =>
      $composableBuilder(column: $table.stars, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<int> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$PendingSyncEventsTableTableManager
    extends
        RootTableManager<
          _$SyncDatabase,
          $PendingSyncEventsTable,
          PendingSyncEvent,
          $$PendingSyncEventsTableFilterComposer,
          $$PendingSyncEventsTableOrderingComposer,
          $$PendingSyncEventsTableAnnotationComposer,
          $$PendingSyncEventsTableCreateCompanionBuilder,
          $$PendingSyncEventsTableUpdateCompanionBuilder,
          (
            PendingSyncEvent,
            BaseReferences<
              _$SyncDatabase,
              $PendingSyncEventsTable,
              PendingSyncEvent
            >,
          ),
          PendingSyncEvent,
          PrefetchHooks Function()
        > {
  $$PendingSyncEventsTableTableManager(
    _$SyncDatabase db,
    $PendingSyncEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncEventsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> childId = const Value.absent(),
                Value<String> activityId = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int?> stars = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
              }) => PendingSyncEventsCompanion(
                id: id,
                childId: childId,
                activityId: activityId,
                score: score,
                stars: stars,
                metadata: metadata,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int childId,
                required String activityId,
                required int score,
                Value<int?> stars = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                required String updatedAt,
                Value<String?> deletedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<int> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                Value<int?> syncedAt = const Value.absent(),
              }) => PendingSyncEventsCompanion.insert(
                id: id,
                childId: childId,
                activityId: activityId,
                score: score,
                stars: stars,
                metadata: metadata,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                status: status,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                syncedAt: syncedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingSyncEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SyncDatabase,
      $PendingSyncEventsTable,
      PendingSyncEvent,
      $$PendingSyncEventsTableFilterComposer,
      $$PendingSyncEventsTableOrderingComposer,
      $$PendingSyncEventsTableAnnotationComposer,
      $$PendingSyncEventsTableCreateCompanionBuilder,
      $$PendingSyncEventsTableUpdateCompanionBuilder,
      (
        PendingSyncEvent,
        BaseReferences<
          _$SyncDatabase,
          $PendingSyncEventsTable,
          PendingSyncEvent
        >,
      ),
      PendingSyncEvent,
      PrefetchHooks Function()
    >;

class $SyncDatabaseManager {
  final _$SyncDatabase _db;
  $SyncDatabaseManager(this._db);
  $$PendingSyncEventsTableTableManager get pendingSyncEvents =>
      $$PendingSyncEventsTableTableManager(_db, _db.pendingSyncEvents);
}
