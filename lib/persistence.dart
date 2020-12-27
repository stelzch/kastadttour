import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:synchronized/synchronized.dart';

class LocationInfo {
  final String id;
  final String name;
  final String description;
  final String coverImagePath;
  final String audioPath;
  final DateTime lastVisit;

  const LocationInfo(
      {String this.id,
      String this.name,
      String this.description,
      String this.coverImagePath,
      String this.audioPath,
      DateTime this.lastVisit});

  LocationInfo copyWith(
      {String id,
      String name,
      String description,
      String coverImagePath,
      String audioPath,
      DateTime lastVisit}) {
    return LocationInfo(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        coverImagePath: coverImagePath ?? this.coverImagePath,
        audioPath: audioPath ?? this.audioPath,
        lastVisit: lastVisit ?? this.lastVisit);
  }

  LocationInfo copyWithoutVisit() {
    return LocationInfo(
        id: id,
        name: name,
        description: description,
        coverImagePath: coverImagePath,
        audioPath: audioPath);
  }
}

class LocationInfoDB {
  static List<LocationInfo> cachedLocations = new List<LocationInfo>();

  static bool allCached = false;

  static Database db;
  static Lock dbCreationLock = new Lock();

  static Stream<LocationInfo> get() async* {
    if (allCached) {
      for (var x in cachedLocations) yield x;
      return;
    }
    await initDatabase();

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
          audioPath: dir + info['audio'],
          lastVisit: await getLastVisit(locationId));

      assert(cachedLocations.map((e) => e.id).contains(location.id) == false,
          "ERROR: Location id '${location.id}' is not unique");

      cachedLocations.add(location);
      yield location;
    }

    allCached = true;
  }

  static Future createDatabase(Database db, int version) async {
    await db.execute(
        "CREATE TABLE lastVisit(locationName TEXT, timestamp INTEGER)");
  }

  static Future initDatabase() async {
    // If the database is initialized, we can simply return
    if (db != null) return;

    // If not, we must open it. To prevent multiple calls, we lock other threads out
    await dbCreationLock.synchronized(() async {
      db = await openDatabase(join(await getDatabasesPath(), 'lastVisit.db'),
          onCreate: createDatabase, version: 1);
    });
  }

  static void updateLastVisit(LocationInfo info) async {
    await initDatabase();

    int rowsUpdated = await db.update(
        'lastVisit',
        {
          // @TODO: rename this parameter to locationId
          'locationName': info.id,
          'timestamp': info.lastVisit.millisecondsSinceEpoch
        },
        where: "locationName = ?",
        whereArgs: [info.id]);

    if (rowsUpdated == 0) {
      // The location was not present yet in the database
      int rowsInserted = await db.insert(
        'lastVisit',
        {
          'locationName': info.id,
          'timestamp': info.lastVisit.millisecondsSinceEpoch
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      assert(rowsInserted == 1);
    }
    print("VIsit updated, ${rowsUpdated}");

    int idx = cachedLocations.indexWhere((e) => e.id == info.id);

    // If the element is not cached, we do not need to update it
    if (idx == -1) return;

    cachedLocations[idx] = info;
  }

  static Future<DateTime> getLastVisit(String locationId) async {
    List<Map<String, dynamic>> r = await db.query("lastVisit",
        where: "locationName = ?",
        columns: ["timestamp"],
        whereArgs: [locationId],
        limit: 1);

    if (r.length == 0) return null;

    return DateTime.fromMillisecondsSinceEpoch(r[0]["timestamp"]);
  }

  static Future forgetLastVisit(LocationInfo info) async {
    int deletedRows = await db.delete(
      'lastVisit',
      where: 'locationName = ?',
      whereArgs: [info.id],
    );
    assert(deletedRows <= 1);

    int idx = cachedLocations.indexWhere((e) => e.id == info.id);

    // If the element is not cached, we do not need to remove the timestamp
    if (idx == -1) return;

    cachedLocations[idx] = info.copyWithoutVisit();
  }
}
