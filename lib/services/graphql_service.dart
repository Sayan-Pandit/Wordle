import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GraphQLService {
  // TODO: REPLACE THIS WITH YOUR ACTUAL ENDPOINT FROM THE CONSOLE
  static const String _endpoint = "https://YOUR_GRAPHQL_ENDPOINT_HERE/v1/graphql";

  static final HttpLink _httpLink = HttpLink(_endpoint);

  static final AuthLink _authLink = AuthLink(
    getToken: () async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        return 'Bearer $token';
      }
      return null;
    },
  );

  static final Link _link = _authLink.concat(_httpLink);

  static final ValueNotifier<GraphQLClient> client = ValueNotifier(
    GraphQLClient(
      link: _link,
      cache: GraphQLCache(store: HiveStore()),
    ),
  );

  /// MATCHING YOUR CONSOLE: CreateNewGame Mutation (Used for saveGame)
  static const String saveGame = """
    mutation CreateNewGame(\$targetWord: String!, \$guesses: String!, \$gameStatus: String!, \$currentLevel: Int!) {
      game_insert(data: {
        targetWord: \$targetWord,
        guesses: \$guesses,
        gameStatus: \$gameStatus,
        currentLevel: \$currentLevel
      })
    }
  """;

  /// MATCHING YOUR CONSOLE: GetDailyChallengeByDate Query
  static const String getDailyChallenge = """
    query GetDailyChallengeByDate(\$date: Date!) {
      dailyChallenges(where: {date: {eq: \$date}}, limit: 1) {
        word
        explanation
      }
    }
  """;

  /// MATCHING YOUR CONSOLE: UpdateUserStats (Used for updateStats)
  static const String updateStats = """
    mutation UpdateUserStats(\$totalGames: Int!, \$wins: Int!, \$currentStreak: Int!, \$maxStreak: Int!, \$guessDistribution: String!) {
      gameStatistics_insert(data: {
        totalGames: \$totalGames,
        wins: \$wins,
        currentStreak: \$currentStreak,
        maxStreak: \$maxStreak,
        guessDistribution: \$guessDistribution
      })
    }
  """;

  /// Mutation to sync user profile (Upsert)
  static const String upsertUser = """
    mutation UserUpsert(\$username: String!, \$email: String!, \$profilePictureUrl: String) {
      user_insert(data: {
        username: \$username,
        email: \$email,
        profilePictureUrl: \$profilePictureUrl
      })
    }
  """;

  /// Query to fetch user profile and stats
  static const String getUserData = """
    query GetUserData {
      user {
        username
        profilePictureUrl
        gameStatistics {
          totalGames
          wins
          currentStreak
          maxStreak
          guessDistribution
        }
      }
    }
  """;

  static Future<QueryResult> mutate(String mutation, Map<String, dynamic> variables) async {
    return await client.value.mutate(MutationOptions(
      document: gql(mutation),
      variables: variables,
    ));
  }

  static Future<QueryResult> query(String query, Map<String, dynamic> variables) async {
    return await client.value.query(QueryOptions(
      document: gql(query),
      variables: variables,
      fetchPolicy: FetchPolicy.networkOnly,
    ));
  }
}
