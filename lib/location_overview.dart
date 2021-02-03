import 'package:flutter/material.dart';
import 'audio.dart';
import 'persistence.dart';
import 'dart:async';
import 'dart:math';
import 'animation.dart';

class LocationOverview extends StatefulWidget {
  static const routeName = "/locationOverview";
  @override
  State<LocationOverview> createState() => LocationOverviewState();
}

class LocationOverviewState extends State<LocationOverview> {
  StreamSubscription dbStream;

  @override
  void initState() {
    super.initState();

    dbStream = LocationInfoDB.updateStream().listen(dbUpdated);
  }

  void dbUpdated(_) {
    setState(() {});
  }

  Widget _getNthChildCard(BuildContext ctx, int i) {
    assert(LocationInfoDB.allCached, "LocationInfoDB not loaded properly");
    return LocationCard(info: LocationInfoDB.cachedLocations[i]);
  }

  @override
  Widget build(BuildContext ctx) {
    assert(LocationInfoDB.allCached, "LocationInfoDB not loaded properly");
    return Scaffold(
        appBar: AppBar(title: Text("Übersicht")),
        body: ListView.builder(
            itemBuilder: _getNthChildCard,
            itemCount: LocationInfoDB.cachedLocations.length,
            padding: const EdgeInsets.only(left: 25, right: 25)));
  }

  @override
  void dispose() {
    dbStream?.cancel();
    super.dispose();
  }
}

enum LocationCardAction { markUnvisited }

class LocationCard extends StatefulWidget {
  final LocationInfo info;

  LocationCard({Key key, this.info}) : super(key: key);

  State<LocationCard> createState() => LocationCardState();
}

class LocationCardState extends State<LocationCard> {
  LocationInfo info;

  void initState() {
    super.initState();

    this.info = widget.info;
  }

  void gotoLocationPage(BuildContext ctx) {
    Navigator.of(ctx).push(createAnimatedRoute(LocationPage(), info));
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
                  Expanded(
                      child: Row(children: [
                    Flexible(
                        child: Text(info.name,
                            style: Theme.of(ctx).textTheme.headline5,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left)),
                    Text((info.lastVisit != null) ? " ✅" : "")
                  ])),
                  PopupMenuButton<LocationCardAction>(
                    onSelected: cardAction,
                    itemBuilder: (BuildContext ctx) =>
                        <PopupMenuEntry<LocationCardAction>>[
                      const PopupMenuItem<LocationCardAction>(
                        value: LocationCardAction.markUnvisited,
                        child: Text("Markiere als unbesucht"),
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

  String datetimeToString(DateTime t) {
    int secondsElapsed =
        ((DateTime.now().millisecondsSinceEpoch - t.millisecondsSinceEpoch) /
                1000)
            .round();
    assert(secondsElapsed >= 0); // No futures handled here

    if (secondsElapsed <= 0) {
      return "bald";
    } else if (secondsElapsed == 0) {
      return "jetzt";
    } else if (secondsElapsed <= 60) {
      return "vor ${secondsElapsed}s";
    } else if (secondsElapsed <= 60 * 60) {
      int minutesElapsed = (secondsElapsed / 60).round();
      return "vor ${minutesElapsed}min";
    } else if (secondsElapsed <= 60 * 60 * 24) {
      int hoursElapsed = (secondsElapsed / 60 / 60).round();
      return "vor ${hoursElapsed}h";
    } else {
      return t.toString();
    }
  }

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
              child: Column(children: [
                Text(info.name,
                    style: textTheme.headline4,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1),
                Padding(
                    child: Text(info.description, style: textTheme.bodyText2),
                    padding: EdgeInsets.only(top: 10, bottom: 50)),
                Text((info.lastVisit == null)
                    ? ""
                    : "Zuletzt besucht: ${datetimeToString(info.lastVisit)}"),
              ], crossAxisAlignment: CrossAxisAlignment.start)),
        ])),
        floatingActionButton: PlayButton(info));
  }
}
