part of abagon_dao_objectory;

class ObjectoryDaoImplementation extends DaoImplementation {

  String _dbUri;
  Objectory _db;
  
  ObjectoryDaoImplementation(this._dbUri);
  
  Future init() {
    objectory = _db = new ObjectoryDirectConnectionImpl( _dbUri, () {
      for( var entity in entities ) {
        _db.registerClass( entity, ()=>createEntity(entity) );
      }
    }, false );
    return _db.initDomainModel();
  }
  
  Future close() {
    return new Future.value(_db.close());
  }
}

abstract class ObjectoryDao<T extends ModelEntity,ID> implements Dao<T,ID> {

  final String _collectionName;
  final ObjectoryDaoImplementation _daoImpl;
  
  const ObjectoryDao(this._collectionName,this._daoImpl);
  
  ObjectoryQueryBuilder get _query => new ObjectoryQueryBuilder(_collectionName);
  Objectory get _db => _daoImpl._db;

  Future<T> getById( ObjectId id ) {
    var selector = _query.eq("_id", id);
    return _db.findOne(selector);
  }
  
  Future<ObjectId> save( T entity ) {
    return _db.save(entity).then( (_) {
      return entity.id;
    });
  }

  Future<List<T>> findAll() {
    return _wrapList( _db.find( _query ), _daoImpl.createList(_collectionName) );
  }
  
  Future delete( T entity ) {
    return _db.remove(entity);
  }
  
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
  
}

abstract class ObjectoryModelEntity<ID> extends PersistentObject implements ModelEntity<ID> {
  
  final String _dbType; 
  
  ObjectoryModelEntity(this._dbType);
  
  String get dbType => _dbType;
}