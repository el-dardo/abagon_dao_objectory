import "dart:async";

import "./model/entities.dart"; 
import "./model/impl/objectory.dart"; 

const DB_URI = 'mongodb://127.0.0.1/facturiva';

/**
 * This is an example of an application using abagon_dao. It first imports the 
 * abstract model and then its objectory specific implementation. 
 * NOTE: No library outside of this one (which initializes the model calling 
 * [initializeModel]) should import the model implementation library.
 */
void main() {
  initializeModel(DB_URI).then( (_) {
    var dao = new EntryDao();
    var now = new DateTime.now();
    dao.findAll().then( (entries) {
      print( "findAll: entries is List<Entry> => "+(entries is List<Entry>).toString() );
      for( var entry in entries ) {
        print("  +---> $entry");
      }
    }).then( (_) {
      return dao.findByMonth(now);
    }).then( (entries) {
      print( "findByMonth(${now}): entries is List<Entry> => "+(entries is List<Entry>).toString() );
      for( var entry in entries ) {
        print("  +---> $entry");
      }
    }).then( (_) {
      var entry = new Entry( now, 6, "lili" );
      return dao.save(entry);
    }).then( (id) {
      print("CREATED: ${id}");
      return dao.getById(id);
    }).then( (entry) {
      print("  +---> getById:   $entry");
      return dao.getByDate(now);
    }).then( (entry) {
      print("  +---> getByDate: $entry");
    }).then( (_) {
      closeModel();
    });
  });
}
