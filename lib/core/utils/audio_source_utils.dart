import 'package:just_audio/just_audio.dart';

class BytesAudioSource extends StreamAudioSource {
  final List<int> _bytes;
  BytesAudioSource(this._bytes);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: (end ?? _bytes.length) - (start ?? 0),
      offset: start ?? 0,
      stream: Stream.value(_bytes.sublist(start ?? 0, end ?? _bytes.length)),
      contentType: 'audio/mpeg',
    );
  }
}
