import 'package:flutter/material.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class PlayButton extends StatefulWidget {
  final String audioPath;
  final String name;

  const PlayButton(this.name, this.audioPath);
  State<PlayButton> createState() => PlayButtonState(name, audioPath);
}

class PlayButtonState extends State<PlayButton> {
  bool _audioInitialized = false;
  FlutterSoundPlayer _player = FlutterSoundPlayer();
  String audioPath;
  String name;
  Track track;

  PlayButtonState(String name, String audioPath) {
    this.audioPath = audioPath;
    this.name = name;
  }

  @override
  void initState() {
    super.initState();

    this.audioPath = audioPath;

    _player.openAudioSession(withUI: true).then((v) {
      setState(() {
        _audioInitialized = true;
      });
    });
  }

  @override
  void dispose() {
    _player.closeAudioSession();
    _player = null;

    super.dispose();
  }

  void buttonPressed() {
    if (!_player.isPlaying) {
      play();
    } else {
      stop();
    }
  }

  void updateIcons() {
    setState(() {});
  }

  Future<Track> createTrack() async {
    return Track(
        trackTitle: name,
        dataBuffer: Uint8List.sublistView(await rootBundle.load(audioPath)),
        codec: Codec.mp3);
  }

  void play() async {
    if (!_audioInitialized) return;

    // Create the track if does not exist already
    if (track == null) {
      var t = await createTrack();
      setState(() {
        track = t;
      });
    }

    print("Starting playback");

    await _player.startPlayerFromTrack(
      track,
      onSkipForward: null,
      onSkipBackward: null,
      whenFinished: updateIcons,
    );

    updateIcons();
  }

  void stop() async {
    await _player.stopPlayer();

    updateIcons();
  }

  IconData _getIcon() {
    return _player.isPlaying ? Icons.stop : Icons.play_arrow;
  }

  @override
  Widget build(BuildContext ctx) {
    return FloatingActionButton(
      child: Icon(_getIcon()),
      onPressed: buttonPressed,
    );
  }
}
