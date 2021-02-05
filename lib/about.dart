import "package:flutter/material.dart";
import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class AboutPage extends StatefulWidget {
  static final String routeName = "/about";
  State<AboutPage> createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {
  String imageRights = "";

  @override
  void initState() {
    super.initState();

    rootBundle
        .loadString('assets/locations/list.yml')
        .then((String index) async {
      YamlList l = loadYaml(index);
      String collection = "";
      for (String locationId in l) {
        var dir = 'assets/locations/${locationId}/';
        YamlMap info = loadYaml(await rootBundle.loadString(dir + 'info.yml'));

        if (info["cover"].containsKey('attribution')) {
          var name = info['name'];
          var user = info['cover']['attribution'].split(" ")[0] ?? "unbekannt";
          collection += " - $name von $user\n";
        }
      }

      setState(() {
        imageRights = collection;
      });
    });
  }

  @override
  Widget build(BuildContext ctx) {
    TextTheme tt = Theme.of(ctx).textTheme;

    return Scaffold(
        appBar: AppBar(title: Text("Über die App")),
        body: Padding(
          padding: EdgeInsets.all(10),
          child: Column(children: [
            Text(
                "Diese App habe ich im Rahmen einer Uni-Vorlesung entwickelt. Wenn sie dir gefällt, kannst du gerne mithelfen: auf github.com/stelzch/kastadttour gibt es mehr Information dazu, egal ob du Code oder neue Orte hinzufügen möchtest."),
            Padding(
                padding: EdgeInsets.only(top: 15),
                child:
                    Row(children: [Text("Bildnachweise", style: tt.subtitle)])),
            Text(
                "Einige Bilder die in der Ortsübersicht verwendet werden sind von der Wikimedia Commons. Es folgt eine Auflistung: "),
            Text(imageRights),
          ]),
        ));
  }
}
