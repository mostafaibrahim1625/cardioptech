import '../../data/models/video_model.dart';

abstract class VideoRepository {
  Future<List<VideoModel>> getVideosList();
  Future<VideoModel> getVideoDetails(int videoId);
}
