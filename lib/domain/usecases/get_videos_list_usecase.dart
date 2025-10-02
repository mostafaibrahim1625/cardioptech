import '../../data/models/video_model.dart';
import '../repositories/video_repository.dart';

class GetVideosListUseCase {
  final VideoRepository _repository;

  GetVideosListUseCase({required VideoRepository repository}) : _repository = repository;

  Future<List<VideoModel>> call() async {
    return await _repository.getVideosList();
  }
}
