library model_impl_objectory;

import "dart:async";

import "package:abagon_dao_objectory/abagon_dao_objectory.dart";

import "../entities.dart";

/**
 * This is the implementation of the abstract example model for the objectory
 * DB driver. This library must import the abstract model and one of the 
 * abagon_dao implementations, depending on which DB driver is going to be
 * used. 
 */

/**
 * Call this method to initialize this model implementation
 */
Future initializeModel( String dbUri ) {
  return initializeAbagonDao( new ObjectoryDaoImplementation(dbUri)
      ..registerClass( Entry, (daoImpl)=>new _EntryDao(daoImpl), ()=>new _Entry(), ()=>new List<_Entry>() )
  );
}

/**
 * Call this method to shutdown this model implementation
 */
Future closeModel() {
  return closeAbagonDao();
}

/**
 * This is the objectory specific implementation of the abstract [ModelEntity]
 * named [Entry].
 */
class _Entry extends ObjectoryModelEntity implements Entry {

  _Entry([DateTime date, num hours, String activity]) : super("Entry") {
    this.date = date;
    this.hours = hours;
    this.activity = activity;
  }

  DateTime get date => getProperty("date");
  set date(DateTime value) => setProperty("date",value);
  
  num get hours => getProperty("hours");
  set hours( num value ) => setProperty("hours",value);

  String get activity => getProperty("activity");
  set activity( String value ) => setProperty("activity",value);

}

/**
 * This is the objectory specific implementation of the abstract [Dao]
 * named [EntryDao].
 */
class _EntryDao extends ObjectoryDao<_Entry> implements EntryDao {
  
  _EntryDao(ObjectoryDaoImplementation daoImpl) : super(Entry,daoImpl);

  Future<Entry> getByDate( DateTime date ) {
    var query = where.eq( "date", date );
    return collection.find( query ).then( (items) {
      if( items.length==1 ) {
        return items[0];
      } else {
        return null;
      }
    });
  }
  
  Future<List<Entry>> findByMonth( DateTime month ) {
    var start = new DateTime(month.year,month.month,1);
    var end = new DateTime(month.year,month.month+1,1);
    var query = where.inRange("date", start, end, minInclude: true, maxInclude: false);
    return collection.find( query ) as Future<List<Entry>>;
  }
  
}

