import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'dart:typed_data';

class LocationOverview extends StatefulWidget {
  @override
  State<LocationOverview> createState() => LocationOverviewState();
}

class LocationOverviewState extends State<LocationOverview> {
  List<LocationCard> cards;
  int numCards = 0;

  @override
  void initState() {
    cards = new List<LocationCard>();

    LocationInfoLoader.get().listen((locInfo) {
      setState(() {
        cards.add(LocationCard(info: locInfo));
        numCards = cards.length;
      });
    });
  }

  Widget _getNthChildCard(BuildContext ctx, int i) {
    return cards[i];
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
        appBar: AppBar(title: Text("Overview")),
        body: ListView.builder(
            itemBuilder: _getNthChildCard,
            itemCount: numCards,
            padding: const EdgeInsets.only(left: 25, right: 25)));
  }
}

class LocationCard extends StatelessWidget {
  final LocationInfo info;

  LocationCard({Key key, LocationInfo this.info}) : super(key: key);

  void gotoLocationPage(BuildContext ctx) {
    Navigator.pushNamed(ctx, LocationPage.routeName, arguments: info);
  }

  @override
  Widget build(BuildContext ctx) {
    return Card(
        margin: EdgeInsets.only(top: 8, bottom: 8),
        child: Column(children: [
          AspectRatio(
              aspectRatio: 3 / 2,
              child: Image(
                  image: AssetImage(info.coverImagePath), fit: BoxFit.cover)),
          Padding(
              padding: EdgeInsets.only(top: 6, left: 8, right: 8, bottom: 0),
              child: Column(children: [
                Row(children: [
                  Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Text(info.name,
                          style: Theme.of(ctx).textTheme.headline5,
                          textAlign: TextAlign.left)),
                ], mainAxisAlignment: MainAxisAlignment.start),
                Padding(
                  padding: EdgeInsets.only(top: 5, bottom: 5),
                  child: Text(
                    info.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(children: [
                  FlatButton(
                      child: Text("Mehr", style: TextStyle(color: Colors.blue)),
                      onPressed: () {
                        gotoLocationPage(ctx);
                      }),
                ], mainAxisAlignment: MainAxisAlignment.end),
              ]))
        ]));
  }
}

class LocationPage extends StatelessWidget {
  static const routeName = "/locationPage";
  @override
  Widget build(BuildContext ctx) {
    var textTheme = Theme.of(ctx).textTheme;

    LocationInfo info = ModalRoute.of(ctx).settings.arguments;
    return Scaffold(
        appBar: AppBar(title: Text(info.name)),
        body: SingleChildScrollView(
            child: Column(children: [
          Image(image: AssetImage(info.coverImagePath), fit: BoxFit.cover),
          Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(children: [Text(info.name, style: textTheme.headline4)]),
                  Padding(
                      child: Text(info.description, style: textTheme.bodyText2),
                      padding: EdgeInsets.only(top: 10, bottom: 50)),
                ],
              )),
        ])),
        floatingActionButton: PlayButton(info.name, info.audioPath));
//        floatingActionButton: FloatingActionButton(
//            child: Icon(Icons.play_circle_filled), onPressed: () {}));
  }
}

class LocationInfo {
  final String id;
  final String name;
  final String description;
  final String coverImagePath;
  final String audioPath;

  const LocationInfo(
      {String this.id,
      String this.name,
      String this.description,
      String this.coverImagePath,
      String this.audioPath});
}

class LocationInfoLoader {
  static List<LocationInfo> cachedLocations = new List<LocationInfo>();
  static bool allCached = false;

  static Stream<LocationInfo> get() async* {
    if (allCached) {
      for (var x in cachedLocations) yield x;
    }

    String index = await rootBundle.loadString('assets/locations/list.yml');
    YamlList l = loadYaml(index);
    for (String locationId in l) {
      var dir = 'assets/locations/${locationId}/';
      YamlMap info = loadYaml(await rootBundle.loadString(dir + 'info.yml'));

      var location = new LocationInfo(
          id: locationId,
          name: info['name'],
          description: info['description'],
          coverImagePath: dir + info['cover']['src'],
          audioPath: dir + info['audio']);
      cachedLocations.add(location);
      yield location;
    }
  }
}

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
