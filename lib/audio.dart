import 'package:flutter/material.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'dart:typed_data';
import 'persistence.dart';
import 'package:flutter/services.dart' show rootBundle;

FlutterSoundPlayer _player;
bool _audioInitialized = false;

void initAudio() async {
  _player = FlutterSoundPlayer();
  _player.openAudioSession(withUI: true).then((v) {
    _audioInitialized = true;
  });
}

Future<Track> createTrack(LocationInfo info) async {
  return Track(
      trackTitle: info.name,
      dataBuffer: Uint8List.sublistView(await rootBundle.load(info.audioPath)),
      codec: Codec.mp3);
}

/* Create the track and start playing it, but immediately pause it. Then the
 * user can request playback by pressing a button on the bluetooth device
 */
void queueAudio(LocationInfo info) async {
  Track t = await createTrack(info);

  _player.startPlayerFromTrack(
    t,
    onSkipForward: null,
    onSkipBackward: null,
    onPaused: (bool wasPlaying) {
      if (wasPlaying) {
        _player.pausePlayer();
      } else {
        _player.resumePlayer();
      }
    },
    whenFinished: () {
      // Mark the area as visited
      LocationInfo modified = info.copyWith(lastVisit: DateTime.now());
      LocationInfoDB.updateLastVisit(modified).then((v) {
        print("Finished DB UPdate");
      });
      _player.stopPlayer();
      print("Done");
    },
  ).then((v) {
    _player.pausePlayer();
  });
}

/* Dequeue the audio if the user has left the zone */
void dequeueAudio() {
  if (_player.isPaused) _player.stopPlayer();
}

class PlayButton extends StatefulWidget {
  final LocationInfo info;

  const PlayButton(this.info);
  State<PlayButton> createState() => PlayButtonState(info: info);
}

class PlayButtonState extends State<PlayButton> {
  final LocationInfo info;

  PlayButtonState({LocationInfo this.info}) : super();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _player.stopPlayer();

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

  void play() async {
    print("Starting track");
    if (!_audioInitialized) return;

    var t = await createTrack(info);

    print("Starting playback");
    await _player.startPlayerFromTrack(
      t,
      onSkipForward: null,
      onSkipBackward: null,
      whenFinished: () {
        _player.stopPlayer();
        updateIcons();
      },
    );

    updateIcons();
  }

  void stop() async {
    await _player.stopPlayer();

    updateIcons();
  }

  IconData _getIcon() {
    if (_player == null) return Icons.play_arrow;
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
