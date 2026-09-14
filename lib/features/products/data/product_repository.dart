import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/product.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<Product>> fetchProducts() async {
    final response = await _apiClient.get(ApiConstants.products);
    if (response is Map && response['products'] is List) {
      final list = response['products'] as List;
      return list.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    }
    return [];
  }
}
