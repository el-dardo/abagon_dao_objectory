part of abagon_dao_objectory;

class ObjectoryDaoImplementation extends DaoImplementation {

  final String _dbUri;
  Objectory _db;
  
  ObjectoryDaoImplementation(this._dbUri)
  {
    _db = new ObjectoryDirectConnectionImpl( _dbUri, internalRegisterClassesCallback, false );
    objectory = _db;
  }

  ObjectoryDaoImplementation.test(this._dbUri,this._db);
  
  Future init() => _db.initDomainModel();
  
  Future close() => new Future.sync( () => 
    _db.close() 
  );

  /**
   * This is to be called from [ObjectoryDirectConnectionImpl.initDomainModel],
   * not from outside but it is made public for unit tests.
   */
  void internalRegisterClassesCallback() {
    for( var entity in entities ) {
      _db.registerClass( entity, ()=>createEntity(entity), ()=>createList(entity) );
    }
  }
  
}

abstract class ObjectoryDao<T extends ObjectoryModelEntity> implements Dao<T> {

  final Type _collection;
  final ObjectoryDaoImplementation _daoImpl;
  
  const ObjectoryDao(this._collection,this._daoImpl);
  
  ObjectoryCollection get collection => _db[_collection];
  Objectory get _db => _daoImpl._db;

  Future<T> getById( String id ) {
    //return safeRun( () {
      return collection.find( where.id( new ObjectId.fromHexString(id) ) ).then( (items) {
        if( items.length==1 ) {
          return items[0];
        } else {
          return null;
        }
      });
      /*
    }).catchError( (err) {
      // TODO: remove this when objectory is fixed
      if( err is DaoStoreException && err.cause is RangeError ) {
        throw new DaoItemNotFoundException(_collection, id);
      } else {
        throw err;
      }
    });
    */
  }
  
  Future<String> save( T entity ) //=> safeRun( () {
    => _db.save(entity).then( (_) 
      => entity.uniqueId
    );
  //});

  Future<List<T>> findAll()// => safeRun( () {
    => //_wrapList( 
        _db[_collection].find();
        //, _daoImpl.createList(_collection) );
  //});
  
  Future delete( T entity )// => safeRun( () {
    => _db.remove(entity);
  //});
  
  /*
  Future<T> _wrap( Future<PersistentObject> future ) => future;

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
  */
  
  /**
   * Safely execute a [computation] catching all possible exceptions. 
   */
  /*
  Future safeRun( computation() ) {
    return new Future.sync( () {
      return computation();      
    }).catchError( (err) {
      throw new DaoStoreException(err);
    });
  }
  */
}

abstract class ObjectoryModelEntity extends PersistentObject implements ModelEntity {
  
  final String _dbType; 
  
  ObjectoryModelEntity(this._dbType);
  
  String get dbType => _dbType;
  
  String get uniqueId => id.toHexString();
  set uniqueId( String value ) => id = (value==null) ? null : new ObjectId.fromHexString(value);

}
