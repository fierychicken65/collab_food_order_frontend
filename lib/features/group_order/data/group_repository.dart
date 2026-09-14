import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class GroupRepository {
  final ApiClient _apiClient;

  GroupRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<Map<String, dynamic>> createGroup(String hostDisplayName) async {
    final response = await _apiClient.post(
      ApiConstants.groups,
      body: {'hostDisplayName': hostDisplayName},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> joinGroup(String code, String displayName) async {
    final response = await _apiClient.post(
      ApiConstants.joinGroup,
      body: {'code': code, 'displayName': displayName},
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchSessionState(String sessionId) async {
    final response = await _apiClient.get('${ApiConstants.groups}/$sessionId');
    return response as Map<String, dynamic>;
  }
}
