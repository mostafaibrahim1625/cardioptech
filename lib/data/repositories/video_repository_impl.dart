import '../../domain/repositories/video_repository.dart';
import '../models/video_model.dart';
import '../services/api_service.dart';

class VideoRepositoryImpl implements VideoRepository {
  final ApiService _apiService;

  VideoRepositoryImpl({required ApiService apiService}) : _apiService = apiService;

  @override
  Future<List<VideoModel>> getVideosList() async {
    try {
      return await _apiService.getVideosList();
    } catch (e) {
      throw Exception('Failed to fetch videos list: $e');
    }
  }

  @override
  Future<VideoModel> getVideoDetails(int videoId) async {
    try {
      return await _apiService.getVideoDetails(videoId);
    } catch (e) {
      throw Exception('Failed to fetch video details: $e');
    }
  }
}
