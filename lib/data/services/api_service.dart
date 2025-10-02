import 'package:dio/dio.dart';
import '../models/video_model.dart';
import '../models/doctor_model.dart';
import '../models/health_data_model.dart';

class ApiService {
  static const String baseUrl = 'https://heartai-backend-production-09ef.up.railway.app';
  late final Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for logging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => print(object),
    ));
  }

  // Get all videos list
  Future<List<VideoModel>> getVideosList() async {
    try {
      final response = await _dio.get('/videos/video_list');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load videos list: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get specific video details
  Future<VideoModel> getVideoDetails(int videoId) async {
    try {
      final response = await _dio.get(
        '/videos/get_video',
        queryParameters: {'id': videoId},
      );
      
      if (response.statusCode == 200) {
        return VideoModel.fromDetailsJson(response.data, videoId);
      } else {
        throw Exception('Failed to load video details: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // Get all doctors list
  Future<List<DoctorModel>> getDoctorsList() async {
    try {
      print('API: Calling /users/doctors/list/');
      final response = await _dio.get('/users/doctors/list/');
      print('API: Response status: ${response.statusCode}');
      print('API: Response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final doctors = data.map((json) => DoctorModel.fromJson(json)).toList();
        print('API: Parsed ${doctors.length} doctors');
        return doctors;
      } else {
        throw Exception('Failed to load doctors list: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('API: DioException: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('API: Unexpected error: $e');
      throw Exception('Unexpected error: $e');
    }
  }

  // Get health data for a user
  Future<HealthDataModel> getHealthData(String userEmail) async {
    try {
      final response = await _dio.get(
        '/vitals/health_data/',
        queryParameters: {'email': userEmail},
      );
      
      if (response.statusCode == 200) {
        return HealthDataModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load health data: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.badResponse) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

}
