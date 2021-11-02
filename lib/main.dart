import 'dart:io';

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:bytestream/buffer_audio_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Asset Music Loader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final AudioPlayer _audioPlayerJust = AudioPlayer();

  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
  @override
  void dispose() {
    _audioPlayerJust.dispose();
    super.dispose();
  }
  
  @override
  void initState(){
    super.initState();
  }

  int startTime = 0;
  int loadToMemTime = 0;
  int beforeSourceTime = 0;
  int afterSourceTime = 0;
  int playStartTime = 0;

  _printTimes(){
    print('**************TotalTime: ${playStartTime-startTime}, loadToMemTime: ${loadToMemTime-startTime}, beforeSourceTime: ${beforeSourceTime-loadToMemTime}, afterSourceTime: ${afterSourceTime-beforeSourceTime}, playStartTime: ${playStartTime-afterSourceTime} ')  ;
  }

  _setupFileSource() async{
    startTime = DateTime.now().millisecondsSinceEpoch;
    var content = await rootBundle
        .load("assets/music/rang.mp3");
    loadToMemTime = DateTime.now().millisecondsSinceEpoch;
    final directory = await getApplicationDocumentsDirectory();
    var file = File("${directory.path}/rang.mp3");
    file.writeAsBytesSync(content.buffer.asUint8List());
    beforeSourceTime = DateTime.now().millisecondsSinceEpoch;
    await _audioPlayerJust.setFilePath(file.path);
    afterSourceTime = DateTime.now().millisecondsSinceEpoch;
    //I/flutter (14016): TotalTime: 838, loadToMemTime: 68, beforeSourceTime: 129, afterSourceTime: 612, playStartTime: 29
  }

  void _play() async {
    if(_audioPlayerJust.audioSource == null){
      _setupAudioPlayerJust();
      await _audioPlayerJust.setAsset('assets/music/rang.mp3');
    }
    await _audioPlayerJust.play();
  }

  void _pause() async{
    await _audioPlayerJust.pause();
  }


  void _seek(Duration position) async{
    await _audioPlayerJust.seek(position);
  }

  void _replay() async{
    await _audioPlayerJust.seek(Duration.zero);
    _play();
  }


  void _setupAudioPlayerJust(){
    // listen for changes in player state
    _audioPlayerJust.playerStateStream.listen((playerState) {
      print('Player Processing State: ${playerState.processingState}');
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = ButtonState.loading;
      }else if (!playerState.playing) {
        buttonNotifier.value = ButtonState.paused;
      } else if (processingState != ProcessingState.completed) {
        playStartTime = DateTime.now().millisecondsSinceEpoch;
        _printTimes();
        buttonNotifier.value = ButtonState.playing;
      }else {
        _replay();
      }
    });

    // listen for changes in play position
    _audioPlayerJust.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });

    // listen for changes in the buffered position
    _audioPlayerJust.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });

    // listen for changes in the total audio duration
    _audioPlayerJust.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _getFilePlayer(),
            // _getBufferedStreamPlayer(),
          ],
        ),
      ),
    );
  }

  _getFilePlayer(){
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ValueListenableBuilder<ButtonState>(
            valueListenable: buttonNotifier,
            builder: (_, value, __) {
              switch (value) {
                case ButtonState.loading:
                  return Container(
                    margin: const EdgeInsets.all(8.0),
                    width: 50.0,
                    height: 50.0,
                    child: const CircularProgressIndicator(),
                  );
                case ButtonState.paused:
                  return IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      size: 50,
                    ),
                    iconSize: 50.0,
                    onPressed: _play,
                  );
                case ButtonState.playing:
                  return IconButton(
                    icon: const Icon(
                      Icons.pause,
                      size: 50,
                    ),
                    iconSize: 50.0,
                    onPressed: _pause,
                  );
                default:
                  return Container();
              }
            },
          ),
          const SizedBox(width: 10,),
          Expanded(
            child: ValueListenableBuilder<ProgressBarState>(
              valueListenable: progressNotifier,
              builder: (_, value, __) {
                return ProgressBar(
                  progress: value.current,
                  buffered: value.buffered,
                  total: value.total,
                  onSeek: _seek,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _getBufferedStreamPlayer(){

  }
}

class ProgressBarState {
  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
  final Duration current;
  final Duration buffered;
  final Duration total;
}

enum ButtonState { paused, playing, loading }