import '../../data/models/video_model.dart';
import '../repositories/video_repository.dart';

class GetVideoDetailsUseCase {
  final VideoRepository _repository;

  GetVideoDetailsUseCase({required VideoRepository repository}) : _repository = repository;

  Future<VideoModel> call(int videoId) async {
    return await _repository.getVideoDetails(videoId);
  }
}
