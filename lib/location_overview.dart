import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

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

    LocationInfoLoader.load().listen((locInfo) {
      print(locInfo.name);
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
    //body: Column(children: _getChildCards()));
  }
}

class LocationCard extends StatelessWidget {
  final LocationInfo info;

  LocationCard({Key key, LocationInfo this.info}) : super(key: key);

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
                      onPressed: () {})
                ], mainAxisAlignment: MainAxisAlignment.end),
              ]))
        ]));
  }
}

class LocationInfo {
  final String name;
  final String description;
  final String coverImagePath;

  const LocationInfo(
      {String this.name, String this.description, String this.coverImagePath});
}

class LocationInfoLoader {
  static Stream<LocationInfo> load() async* {
    String index = await rootBundle.loadString('assets/locations/list.yml');
    YamlList l = loadYaml(index);
    for (String locationName in l) {
      var dir = 'assets/locations/${locationName}/';
      YamlMap info = loadYaml(await rootBundle.loadString(dir + 'info.yml'));

      yield new LocationInfo(
          name: info['name'],
          description: info['description'],
          coverImagePath: dir + info['cover']['src']);
    }
  }
}
