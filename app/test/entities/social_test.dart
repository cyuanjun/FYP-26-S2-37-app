import 'package:flutter_test/flutter_test.dart';
import 'package:wise_workout/entities/enums.dart';
import 'package:wise_workout/entities/feed_post.dart';

void main() {
  group('FeedPost.fromRow', () {
    // Mirrors the gateway's embedded PostgREST row (snake_case, nested).
    final row = <String, dynamic>{
      'id': 'p1',
      'user_id': 'u2',
      'kind': 'workout_share',
      'workout_session_id': 's1',
      'challenge_id': null,
      'level': null,
      'body': 'Evening ride 🚴',
      'created_at': '2026-07-05T10:00:00+00:00',
      'author': {
        'id': 'u2',
        'first_name': 'Alex',
        'last_name': 'Tan',
        'username': 'alex',
        'avatar_url': null,
        'level': 4,
      },
      'session': {
        'id': 's1',
        'user_id': 'u2',
        'workout_type_id': 'wt1',
        'started_at': '2026-07-05T09:00:00+00:00',
        'ended_at': '2026-07-05T09:50:00+00:00',
        'duration_seconds': 3000,
        'distance_meters': 18400,
        'calories_burned': 420,
        'avg_heart_rate': 138,
        'max_heart_rate': 160,
        'feel_rating': 'okay',
        'custom_name': null,
      },
      'likes': [
        {'user_id': 'u1'},
        {'user_id': 'u3'},
      ],
      'comments': [
        {'id': 'c1'},
      ],
    };

    test('decodes post, author, session and computes counts (positive)', () {
      final fp = FeedPost.fromRow(row, me: 'u1');
      expect(fp.post.kind, PostKind.workoutShare);
      expect(fp.author.displayName, 'Alex Tan');
      expect(fp.author.level, 4);
      expect(fp.session!.distanceMeters, 18400);
      expect(fp.likeCount, 2);
      expect(fp.commentCount, 1);
      expect(fp.likedByMe, isTrue);
    });

    test('likedByMe false when I have not liked (negative)', () {
      final fp = FeedPost.fromRow(row, me: 'u9');
      expect(fp.likedByMe, isFalse);
    });

    test('level_up rows carry level and no session', () {
      final levelUp = <String, dynamic>{
        ...row,
        'kind': 'level_up',
        'workout_session_id': null,
        'session': null,
        'level': 3,
        'likes': const [],
        'comments': const [],
      };
      final fp = FeedPost.fromRow(levelUp, me: 'u1');
      expect(fp.post.isLevelUp, isTrue);
      expect(fp.post.level, 3);
      expect(fp.session, isNull);
      expect(fp.likeCount, 0);
    });
  });

  group('Post kind helpers', () {
    test('exactly one is true per kind', () {
      final fp = FeedPost.fromRow(rowWs, me: 'u1').post;
      expect(fp.isWorkoutShare, isTrue);
      expect(fp.isChallengeResult, isFalse);
      expect(fp.isLevelUp, isFalse);
    });
  });
}

final rowWs = <String, dynamic>{
  'id': 'p2',
  'user_id': 'u2',
  'kind': 'workout_share',
  'workout_session_id': 's1',
  'created_at': '2026-07-05T10:00:00+00:00',
  'author': {'id': 'u2', 'username': 'alex'},
  'session': null,
  'likes': const [],
  'comments': const [],
};
