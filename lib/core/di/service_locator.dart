import '../../data/repositories/video_repository_impl.dart';
import '../../data/services/api_service.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/usecases/get_video_details_usecase.dart';
import '../../domain/usecases/get_videos_list_usecase.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Services
  late final ApiService _apiService;
  late final VideoRepository _videoRepository;
  late final GetVideosListUseCase _getVideosListUseCase;
  late final GetVideoDetailsUseCase _getVideoDetailsUseCase;

  // Getters
  ApiService get apiService => _apiService;
  VideoRepository get videoRepository => _videoRepository;
  GetVideosListUseCase get getVideosListUseCase => _getVideosListUseCase;
  GetVideoDetailsUseCase get getVideoDetailsUseCase => _getVideoDetailsUseCase;

  void init() {
    // Initialize services
    _apiService = ApiService();
    _videoRepository = VideoRepositoryImpl(apiService: _apiService);
    _getVideosListUseCase = GetVideosListUseCase(repository: _videoRepository);
    _getVideoDetailsUseCase = GetVideoDetailsUseCase(repository: _videoRepository);
  }
}
