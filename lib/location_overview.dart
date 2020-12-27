import 'package:flutter/material.dart';
import 'audio.dart';
import 'persistence.dart';

class LocationOverview extends StatefulWidget {
  static const routeName = "/locationOverview";
  @override
  State<LocationOverview> createState() => LocationOverviewState();
}

class LocationOverviewState extends State<LocationOverview> {
  List<LocationCard> cards;
  int numCards = 0;

  @override
  void initState() {
    cards = new List<LocationCard>();

    LocationInfoDB.get().listen((locInfo) {
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

enum LocationCardAction { markUnvisited }

class LocationCard extends StatefulWidget {
  final LocationInfo info;

  LocationCard({Key key, LocationInfo this.info}) : super(key: key);

  State<LocationCard> createState() => LocationCardState();
}

class LocationCardState extends State<LocationCard> {
  LocationInfo info;

  void initState() {
    super.initState();

    this.info = widget.info;
  }

  void gotoLocationPage(BuildContext ctx) {
    Navigator.pushNamed(ctx, LocationPage.routeName, arguments: info);
  }

  void cardAction(LocationCardAction action) {
    print(action);
    if (action == LocationCardAction.markUnvisited) {
      LocationInfoDB.forgetLastVisit(info);
      setState(() {
        this.info = info.copyWithoutVisit();
      });
    }
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
                      child: Text(
                          info.name + (info.lastVisit != null ? " ✅" : ""),
                          style: Theme.of(ctx).textTheme.headline5,
                          textAlign: TextAlign.left)),
                  PopupMenuButton<LocationCardAction>(
                    onSelected: cardAction,
                    itemBuilder: (BuildContext ctx) =>
                        <PopupMenuEntry<LocationCardAction>>[
                      const PopupMenuItem<LocationCardAction>(
                        value: LocationCardAction.markUnvisited,
                        child: Text("Mark unvisited"),
                      )
                    ],
                  ),
                ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
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
