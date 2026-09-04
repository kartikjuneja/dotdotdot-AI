import '../../domain/models/model_info.dart';
import 'ai_types.dart';

/// Provider adapter: list models and run chat / media generations.
abstract class AiProvider {
  String get id;

  Future<List<ModelInfo>> listModels();

  Stream<ChatDelta> streamChat(ChatRequest req);

  Future<MediaResult> generateImage(ImageRequest req);

  Future<MediaResult> generateVideo(VideoRequest req);

  Future<MediaResult> generateAudio(AudioRequest req);
}
