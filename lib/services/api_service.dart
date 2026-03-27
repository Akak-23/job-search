import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../exceptions/app_exceptions.dart';

const String _targetBase =
    'https://rest.arbeitsagentur.de/jobboerse/jobsuche-service/pc/v4/app';
const String _apiKey = 'jobboerse-jobsuche';

/// Service for API communication
class ApiService {
  /// Timeout for API requests
  static const Duration _timeout = AppConstants.apiTimeout;

  /// Perform a GET request to the Arbeitsagentur Jobbörse `/jobs` endpoint.
  ///
  /// Throws [ApiException] on API errors, [NetworkException] on network errors,
  /// and [TimeoutException] on timeout.
  static Future<dynamic> getJobs(Map<String, String> params) async {
    try {
      final uri = Uri.parse('$_targetBase/jobs').replace(queryParameters: params);
      final headers = {'X-API-Key': _apiKey};

      final response = await http.get(uri, headers: headers).timeout(
        _timeout,
        onTimeout: () {
          throw ApiException(
            message: AppConstants.errorTimeout,
            originalError: 'HTTP request timeout',
          );
        },
      );

      if (response.statusCode == 200) {
        try {
          return json.decode(response.body);
        } catch (e) {
          throw ApiException(
            message: 'Failed to parse response',
            statusCode: response.statusCode,
            originalError: e.toString(),
          );
        }
      } else if (response.statusCode == 400) {
        throw ApiException(
          message: 'Invalid search parameters',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 401) {
        throw ApiException(
          message: 'Unauthorized access',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 404) {
        throw ApiException(
          message: 'No jobs found',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode >= 500) {
        throw ApiException(
          message: 'Server error. Please try again later.',
          statusCode: response.statusCode,
        );
      } else {
        throw ApiException(
          message: 'Server returned ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } on SocketException {
      throw NetworkException(AppConstants.errorNetworkConnection);
    } catch (e) {
      throw NetworkException('An unexpected error occurred: ${e.toString()}');
    }
  }
}
