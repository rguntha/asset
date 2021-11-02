
import 'dart:async';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';

class BufferAudioSource extends StreamAudioSource {
  final Uint8List _buffer;
  final String _mime;
  BufferAudioSource(this._buffer,this._mime) : super(tag: "Amma");

  @override
  Future<StreamAudioResponse> request([int? start, int? end]){
    print('$start:$end:$_mime');
    int startTime = DateTime.now().millisecondsSinceEpoch;
    start = start ?? 0;
    end = end ?? _buffer.length;
    if(end > _buffer.length){
      end = _buffer.length;
    }
    print('$start:$end');

    Stream<List<int>> stream =
    Stream.value(List<int>.from(_buffer.skip(start).take(end - start)));
    print('**************$start:$end-done. time taken to convert the Uint8List to List<int> ${DateTime.now().millisecondsSinceEpoch - startTime}');

    return Future.value(
      StreamAudioResponse(
        sourceLength: _buffer.length,
        contentLength: end - start,
        offset: start,
        contentType: _mime,
        stream:stream,
        // stream:_streamController.stream,
      ),
    );
  }
}