import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Result of a successful player query.
class PlayerQueryResult {
  final int wave;
  final int seasonalScore;
  final String queryDate;
  final Map<String, dynamic> rawResult;

  const PlayerQueryResult({
    required this.wave,
    required this.seasonalScore,
    required this.queryDate,
    required this.rawResult,
  });
}

/// Simple wrapper for API error cases.
sealed class QueryError {
  const QueryError();
}

class NameNotFound extends QueryError {
  const NameNotFound();
}

class NetworkError extends QueryError {
  final String message;
  const NetworkError(this.message);
}

class TimeoutError extends QueryError {
  const TimeoutError();
}

/// Service that fetches player data from the Grow Castle season API.
///
/// The endpoint URL is assembled from parts at runtime so it is never
/// stored as a single plain-text literal.
class PlayerApiService {
  PlayerApiService._();

  static const Duration _timeout = Duration(seconds: 4);

  // ── URL assembly (not plain text) ──────────────────────────────────────

  static const List<String> __p = [
    'https://',
    'raongames',
    '.com/',
    'growcastle/',
    'restapi/',
    'season/now/',
    'players/',
  ];

  static String _buildUrl(String playerName) {
    return '${__p[0]}${__p[1]}${__p[2]}${__p[3]}${__p[4]}${__p[5]}${__p[6]}${Uri.encodeComponent(playerName)}';
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Fetches player info for [playerName].
  ///
  /// Returns a [PlayerQueryResult] on success, or a [QueryError] on failure.
  static Future<Object /* PlayerQueryResult | QueryError */> query(
      String playerName) async {
    final url = _buildUrl(playerName.trim());
    final uri = Uri.parse(url);

    try {
      final response = await http.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        return const NameNotFound();
      }

      // Explicit UTF-8 decoding.
      final rawBody = utf8.decode(response.bodyBytes);
      final decoded = json.decode(rawBody);
      if (decoded is! Map<String, dynamic>) {
        return const NameNotFound();
      }
      final body = decoded;

      // code — may come as int or String.
      final code = _parseInt(body['code']);
      if (code != 200) {
        return const NameNotFound();
      }

      final result = body['result'];
      if (result is! Map<String, dynamic>) {
        return const NameNotFound();
      }

      final list = result['list'];
      if (list is! List<dynamic> || list.isEmpty) {
        return const NameNotFound();
      }

      final player = list[0];
      if (player is! Map<String, dynamic>) {
        return const NameNotFound();
      }

      final wave = _parseInt(player['wave']);
      final score = _parseInt(player['score']);
      final queryDate = (player['date'] as String?) ?? '';

      return PlayerQueryResult(
        wave: wave,
        seasonalScore: score,
        queryDate: queryDate,
        rawResult: Map<String, dynamic>.from(result),
      );
    } on TimeoutException {
      return const TimeoutError();
    } on http.ClientException {
      return const NetworkError('Network connection failed');
    } catch (e) {
      return NetworkError(e.toString());
    }
  }

  /// Parses [value] to int, handling both `int` and `String` representations.
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }
}
