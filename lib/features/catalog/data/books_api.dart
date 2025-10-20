import 'package:dio/dio.dart';
import '../model/volume.dart';

class BooksApi {
  final Dio _dio;
  final String? apiKey;
  
  static const _base = 'https://www.googleapis.com/books/v1';

  BooksApi({
    required this.apiKey,
    String? androidPackage,
    String? androidCert,
    }): _dio = Dio(BaseOptions(
        baseUrl: _base, 
        connectTimeout: const Duration(seconds: 10),
        headers: {
            if (androidPackage != null && androidPackage.isNotEmpty)
              'X-Android-Package': androidPackage,
            if (androidCert != null && androidCert.isNotEmpty)
              'X-Android-Cert': androidCert,
          },
      )
    );

  /// Ricerca volumi: es. q="android jetpack", "intitle:android", "isbn:9780134685991"
  Future<VolumeList> search({
    required String q,
    int startIndex = 0,
    int maxResults = 20,
    String? orderBy,      // 'relevance' | 'newest'
    String? printType,    // 'all' | 'books' | 'magazines'
    String? langRestrict, // es. 'it'
  }) async {
    final params = {
      'q': q,
      'startIndex': startIndex,
      'maxResults': maxResults.clamp(1, 40),
      if (apiKey != null) 'key': apiKey,
      if (orderBy != null) 'orderBy': orderBy,
      if (printType != null) 'printType': printType,
      if (langRestrict != null) 'langRestrict': langRestrict,
    };

    final res = await _dio.get('/volumes', queryParameters: params);
    return VolumeList.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Volume> getById(String id) async {
    final res = await _dio.get(
      '/volumes/$id', 
      queryParameters: {if (apiKey != null) 'key': apiKey}
    );
    return Volume.fromJson(res.data as Map<String, dynamic>);
  }
}
