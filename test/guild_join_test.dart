import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinjuu_league/data/models/guild_model.dart';
import 'package:shinjuu_league/services/firestore_service.dart';
import 'package:shinjuu_league/viewmodels/guild_viewmodel.dart';

void main() {
  group('FirestoreService.searchGuildsByName', () {
    test('finds guilds whose name starts with the query', () async {
      final firestore = FakeFirebaseFirestore();
      final service = FirestoreService.forFirestore(firestore);
      await firestore.collection('guilds').doc('g1').set(
        Guild(
          guildId: 'g1',
          name: '緋焔の戦士団',
          ownerId: 'owner1',
          memberIds: ['owner1'],
          maxMembers: 30,
          createdAt: DateTime(2026),
        ).toJson(),
      );
      await firestore.collection('guilds').doc('g2').set(
        Guild(
          guildId: 'g2',
          name: '蒼氷の守護者',
          ownerId: 'owner2',
          memberIds: ['owner2'],
          maxMembers: 30,
          createdAt: DateTime(2026),
        ).toJson(),
      );

      final results = await service.searchGuildsByName('緋焔');

      expect(results, hasLength(1));
      expect(results.first.guildId, 'g1');
    });

    test('returns an empty list for an empty query without querying Firestore', () async {
      final service = FirestoreService.forFirestore(FakeFirebaseFirestore());
      final results = await service.searchGuildsByName('');
      expect(results, isEmpty);
    });
  });

  group('GuildViewModel.joinGuild', () {
    test('adds the user to memberIds and links guildId on their profile', () async {
      final firestore = FakeFirebaseFirestore();
      final firestoreService = FirestoreService.forFirestore(firestore);
      await firestore.collection('guilds').doc('g1').set(
        Guild(
          guildId: 'g1',
          name: 'テストギルド',
          ownerId: 'owner1',
          memberIds: ['owner1'],
          maxMembers: 30,
          createdAt: DateTime(2026),
        ).toJson(),
      );
      await firestore.collection('users').doc('newbie').set({
        'uid': 'newbie',
        'name': 'Newbie',
        'guildId': null,
      });

      final viewModel = GuildViewModel(firestoreService: firestoreService);
      addTearDown(viewModel.dispose);

      await viewModel.joinGuild('g1', 'newbie');

      final guildDoc = await firestore.collection('guilds').doc('g1').get();
      expect(guildDoc.data()!['memberIds'], containsAll(['owner1', 'newbie']));

      final userDoc = await firestore.collection('users').doc('newbie').get();
      expect(userDoc.data()!['guildId'], 'g1');
    });

    test('surfaces a failure in state.error and rethrows', () async {
      // No 'g1' guild document exists, so the arrayUnion update() call
      // against a nonexistent doc will fail.
      final firestore = FakeFirebaseFirestore();
      final viewModel = GuildViewModel(
        firestoreService: FirestoreService.forFirestore(firestore),
      );
      addTearDown(viewModel.dispose);

      await expectLater(
        () => viewModel.joinGuild('missing_guild', 'newbie'),
        throwsA(anything),
      );
      expect(viewModel.state.error, isNotNull);
      expect(viewModel.state.isLoading, isFalse);
    });
  });

  group('GuildViewModel.searchGuilds', () {
    test('delegates to FirestoreService.searchGuildsByName', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('guilds').doc('g1').set(
        Guild(
          guildId: 'g1',
          name: 'Alpha Squad',
          ownerId: 'owner1',
          memberIds: ['owner1'],
          maxMembers: 30,
          createdAt: DateTime(2026),
        ).toJson(),
      );

      final viewModel = GuildViewModel(
        firestoreService: FirestoreService.forFirestore(firestore),
      );
      addTearDown(viewModel.dispose);

      final results = await viewModel.searchGuilds('Alpha');
      expect(results.map((g) => g.guildId), contains('g1'));
    });
  });
}
