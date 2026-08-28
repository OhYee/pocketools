import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketools/core/session/session.dart';
import 'package:pocketools/core/session/session_envelope.dart';
import 'package:pocketools/core/session/session_history.dart';

void main() {
  final codec = SessionSnapshotJsonCodec();

  test('strict envelope round-trips session, time, and annotation', () {
    final entry = HistoryEntry(
      session: _session('one'),
      savedAtUtc: DateTime.utc(2026, 8, 23, 10),
      annotation: SessionAnnotation(favorite: true, privateNote: ' local '),
    );

    final decoded = codec.decode(codec.encode(entries: <HistoryEntry>[entry]));

    expect(decoded.issues, isEmpty);
    expect(decoded.entries.single.session.outcome, <String, Object?>{
      'values': <Object?>[1, 2, 3],
    });
    expect(decoded.entries.single.savedAtUtc, DateTime.utc(2026, 8, 23, 10));
    expect(decoded.entries.single.annotation.favorite, isTrue);
    expect(decoded.entries.single.annotation.privateNote, 'local');
  });

  test('decoded nested session collections remain deeply immutable', () {
    final decoded = codec.decode(
      codec.encode(
        entries: <HistoryEntry>[
          HistoryEntry(
            session: _session('immutable'),
            savedAtUtc: DateTime.utc(2026),
          ),
        ],
      ),
    );
    final values = decoded.entries.single.session.outcome['values']! as List;

    expect(() => values.add(4), throwsUnsupportedError);
    expect(() => decoded.entries.clear(), throwsUnsupportedError);
  });

  test('unknown top-level version is quarantined with original text', () {
    const raw = '{"storageSchemaVersion":99,"documents":[]}';

    final decoded = codec.decode(raw);

    expect(decoded.entries, isEmpty);
    expect(
      decoded.issues.single.code,
      SessionLoadIssueCode.unknownStorageVersion,
    );
    expect(decoded.quarantined.single.rawText, raw);
  });

  test('one polluted document is isolated while valid records survive', () {
    final valid = jsonDecode(
      codec.encode(
        entries: <HistoryEntry>[
          HistoryEntry(
            session: _session('valid'),
            savedAtUtc: DateTime.utc(2026),
          ),
        ],
      ),
    ) as Map<String, Object?>;
    final documents = valid['documents']! as List<Object?>;
    documents.add(<String, Object?>{
      'savedAtUtc': 'not-utc',
      'session': <String, Object?>{},
      'annotation': <String, Object?>{},
    });

    final decoded = codec.decode(jsonEncode(valid));

    expect(decoded.entries.single.session.id, 'valid');
    expect(decoded.quarantined, hasLength(1));
    expect(decoded.issues.single.code, SessionLoadIssueCode.invalidDocument);
  });

  test('duplicate ids are isolated instead of replacing the first record', () {
    final raw = jsonDecode(
      codec.encode(
        entries: <HistoryEntry>[
          HistoryEntry(
            session: _session('duplicate'),
            savedAtUtc: DateTime.utc(2026),
          ),
        ],
      ),
    ) as Map<String, Object?>;
    final documents = raw['documents']! as List<Object?>;
    documents.add(jsonDecode(jsonEncode(documents.single)));

    final decoded = codec.decode(jsonEncode(raw));

    expect(decoded.entries, hasLength(1));
    expect(decoded.issues.single.code, SessionLoadIssueCode.duplicateSessionId);
  });

  test(
    'legacy envelope accepts nullable or absent parent and migrates annotation',
    () {
      final current = jsonDecode(
        codec.encode(
          entries: <HistoryEntry>[
            HistoryEntry(
              session: _session('legacy'),
              savedAtUtc: DateTime.utc(2026),
            ),
          ],
        ),
      ) as Map<String, Object?>;
      final document = (current['documents']! as List).single as Map;
      document.remove('annotation');
      (document['session']! as Map).remove('parentSessionId');
      current
        ..['storageSchemaVersion'] = 0
        ..remove('quarantined');

      final decoded = codec.decode(jsonEncode(current));

      expect(decoded.entries.single.session.parentSessionId, isNull);
      expect(decoded.entries.single.annotation.favorite, isFalse);
      expect(decoded.issues.single.code, SessionLoadIssueCode.legacyMigrated);
    },
  );

  test('entry and byte limits fail explicitly', () {
    final oneEntryCodec = SessionSnapshotJsonCodec(
      limits: const SessionStorageLimits(
        maximumEntries: 1,
        maximumSnapshotBytes: 4096,
      ),
    );
    final entries = <HistoryEntry>[
      HistoryEntry(session: _session('one'), savedAtUtc: DateTime.utc(2026)),
      HistoryEntry(session: _session('two'), savedAtUtc: DateTime.utc(2026)),
    ];

    expect(
      () => oneEntryCodec.encode(entries: entries),
      throwsA(isA<SessionStorageException>()),
    );
    final tinyCodec = SessionSnapshotJsonCodec(
      limits: const SessionStorageLimits(
        maximumEntries: 2,
        maximumSnapshotBytes: 16,
      ),
    );
    expect(
      () => tinyCodec.encode(entries: entries.take(1)),
      throwsA(isA<SessionStorageException>()),
    );
  });
}

SessionRecord _session(String id) => SessionRecord(
  id: id,
  toolId: 'fake',
  schemaVersion: 7,
  ruleVersion: 'fake/rule-1',
  algorithmVersion: 'random/v1',
  status: SessionStatus.completed,
  input: const <String, Object?>{
    'nested': <String, Object?>{'enabled': true},
  },
  outcome: const <String, Object?>{
    'values': <Object?>[1, 2, 3],
  },
);
