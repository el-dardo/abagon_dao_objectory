part of abagon_dao_objectory;

class ObjectoryDaoImplementation extends DaoImplementation {

  String _dbUri;
  Objectory _db;
  Function _registerClassesCallback;
  
  ObjectoryDaoImplementation(this._dbUri,[this._db]) {
    _registerClassesCallback = () {
      for( var entity in entities ) {
        _db.registerClass( entity, ()=>createEntity(entity) );
      }
    };
    if( _db==null ) {
      _db = new ObjectoryDirectConnectionImpl( _dbUri, _registerClassesCallback, false );
    }
    objectory = _db;
  }
  
  Future init() {
    return _db.initDomainModel();
  }
  
  Future close() {
    return new Future.value(_db.close());
  }
}

abstract class ObjectoryDao<T extends ObjectoryModelEntity> implements Dao<T> {

  final Type _collection;
  final ObjectoryDaoImplementation _daoImpl;
  
  const ObjectoryDao(this._collection,this._daoImpl);
  
  ObjectoryCollection get collection => _db[_collection];
  Objectory get _db => _daoImpl._db;

  Future<T> getById( String id ) {
    return safeRun( () {
      return collection.find( where.id( new ObjectId.fromHexString(id) ) ).then( (items) {
        if( items.length==1 ) {
          return items[0];
        } else {
          throw new DaoItemNotFoundException(_collection, id);
        }
      });
    }).catchError( (err) {
      // TODO: remove this when objectory is fixed
      if( err is DaoStoreException && err.cause is RangeError ) {
        throw new DaoItemNotFoundException(_collection, id);
      } else {
        throw err;
      }
    });
  }
  
  Future<ObjectId> save( T entity ) => safeRun( () {
    return _db.save(entity).then( (_) {
      return entity.uniqueId;
    });
  });

  Future<List<T>> findAll() => safeRun( () {
    return _wrapList( _db[_collection].find(), _daoImpl.createList(_collection) );
  });
  
  Future delete( T entity ) => safeRun( () {
    return _db.remove(entity);
  });
  
  Future<T> _wrap( Future<PersistentObject> future ) {
    return future;
  }

  // TODO: remove _wrapList wrapping as soon as Objectory implements typed lists in find() 
  Future<List<T>> _wrapList( Future<List<PersistentObject>> future, List<T> list ) {
    var completer = new Completer();
    future.then( (_list) {
      for( var obj in _list ) {
        list.add(obj);
      }
      completer.complete(list);
    }).catchError( (err) {
      completer.completeError(err);
    });
    return completer.future;
  }
  
  /**
   * Safely execute a [computation] catching all possible exceptions. 
   */
  Future safeRun( computation() ) {
    return new Future.sync( () {
      return computation();      
    }).catchError( (err) {
      throw new DaoStoreException(err);
    });
  }
}

abstract class ObjectoryModelEntity extends PersistentObject implements ModelEntity {
  
  final String _dbType; 
  
  ObjectoryModelEntity(this._dbType);
  
  String get dbType => _dbType;
  
  String get uniqueId => id.toHexString();
  set uniqueId( String value ) => id = (value==null) ? null : new ObjectId.fromHexString(value);

}
