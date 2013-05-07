library model;

import "dart:async";
import "package:abagon_dao/abagon_dao.dart";

/**
 * This is the abstract model definition. This library must import abagon_dao
 * only and declare all [ModelEntity]s and [Dao]s used in the application. 
 */

/**
 * [Entry] is the only [ModelEntity] in this example.
 */
abstract class Entry implements ModelEntity<String> {
  DateTime date;
  num hours;
  String activity;
  
  factory Entry([DateTime date, num hours, String activity]) => 
    abagon.createEntity("Entry")
      ..date = date
      ..hours = hours
      ..activity = activity;
      
}

/**
 * [EntryDao] is the [Dao] definition for [Entry]
 */
abstract class EntryDao implements Dao<Entry,String> {
  factory EntryDao() => abagon.createDao("Entry");
  
  Future<Entry> getByDate( DateTime date );
  Future<List<Entry>> findByMonth( DateTime month );
}
