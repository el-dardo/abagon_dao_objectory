library abagon_dao_objectory;

import "package:unittest/unittest.dart";
import "package:unittest/mock.dart";

import "dart:async";
import "package:abagon_dao/abagon_dao.dart";
import 'package:bson/bson.dart';
import 'package:objectory/src/objectory_query_builder.dart';
import 'package:objectory/src/objectory_base.dart';
import 'package:objectory/src/persistent_object.dart';
import 'package:objectory/src/objectory_direct_connection_impl.dart';

part "../lib/src/api.dart";

////////////////////////////////////////////////////////////////////////////////
/// Mocks
class MockObjectory extends Mock implements Objectory {}
class MockObjectoryDaoImplementation extends Mock implements ObjectoryDaoImplementation {
  final Objectory _db;
  MockObjectoryDaoImplementation(this._db);
}
class MockObjectoryCollection extends Mock implements ObjectoryCollection {}
class MockEntity extends Mock implements ObjectoryModelEntity {}

////////////////////////////////////////////////////////////////////////////////
/// Instantiable abstract classes to test
class TestModelEntity extends ObjectoryModelEntity {
  TestModelEntity(String dbType) : super(dbType);
}
class TestObjectoryDao extends ObjectoryDao {
  TestObjectoryDao(Type collection, ObjectoryDaoImplementation daoImpl) : super(collection,daoImpl);
}

////////////////////////////////////////////////////////////////////////////////
/// Tests
void main() {

  group( "ObjectoryDaoImplementation:", () {

    const dbUri = "lili";
    MockObjectory mockDb;
    ObjectoryDaoImplementation impl;

    setUp( () {
      mockDb = new MockObjectory();
      impl = new ObjectoryDaoImplementation( dbUri, mockDb );
    });
    
    test( "init() calls Objectory.initDomainModel()", () {
      
      mockDb.when( callsTo("initDomainModel") ).alwaysReturn( new Future.value() );
      
      return impl.init().then( (_) {
        mockDb.calls("initDomainModel").verify(happenedOnce);
      });
    });

    test( "close() calls close() on Objectory implementation", () {
      
      mockDb.when( callsTo("close") ).alwaysReturn( new Future.value() );

      return impl.close().then((_) {
        mockDb.calls("close").verify(happenedOnce);
      });
    });

    test( "_registerClassesCallback registers domain classes in Objectory", () {
      const types = const [ String, int, bool ];
      
      for( var i=0 ; i<types.length ; i++ ) {
        impl.registerClass( types[i], (_)=>null, ()=>null, ()=>null );
      }
      
      impl._registerClassesCallback();

      for( var i=0 ; i<types.length ; i++ ) {
        mockDb.calls("registerClass",types[i],anything).verify(happenedOnce);
      }
    });

  });

  group( "ObjectoryDao:", () {

    MockObjectory db;
    MockObjectoryDaoImplementation daoImpl;
    TestObjectoryDao dao;
    MockObjectoryCollection collection;
    MockEntity entity;

    setUp( () {
      db = new MockObjectory();
      daoImpl = new MockObjectoryDaoImplementation(db);
      dao = new TestObjectoryDao( MockEntity, daoImpl );
      collection = new MockObjectoryCollection();
      entity = new MockEntity();
      
      //daoImpl.when(callsTo("get _db")).alwaysReturn(db);
      db.when( callsTo("[]",equals(MockEntity)) ).alwaysReturn( collection );
      entity.when(callsTo("get id")).alwaysReturn("lili");
    });
    
    List<MockEntity> _createListOfMockEntitiesWithId(int count) {
      var dbList = new List<MockEntity>();
      for( int i=0 ; i<2 ; i++ ) {
        dbList.add( new MockEntity() );
        dbList[i].when(callsTo("get id")).alwaysReturn(i.toString());
      }
      return dbList;
    }

    test( "getById() calls ObjectoryCollection.find() with correct query", () {

      collection.when( callsTo("find",anything) ).alwaysReturn( new Future.value([new MockEntity()]) );
      
      return dao.getById("lili").then( (entity) {
        var query = collection.calls("find", anything ).first.args[0].toString();
        expect( query, equals(r"ObjectoryQueryBuilder({$query: {_id: ObjectId(lili)}})") );
      });
    });

    test( "save() calls Objectory.save() and returns the entity id", () {
      var entity = new MockEntity();
      
      entity.when(callsTo("get uniqueId")).alwaysReturn("lili");
      db.when( callsTo("save",anything) ).alwaysReturn( new Future.value() );
      
      return dao.save(entity).then( (id) {
        db.calls("save",entity).verify( happenedOnce );
        expect( id, equals("lili") );
      });
    });

    test( "findAll() calls Objectory.find() with correct query and DaoImplementation.createList()", () {
      var dbList = _createListOfMockEntitiesWithId(2);
      
      collection.when( callsTo("find") ).alwaysReturn( new Future.value(dbList) );
      daoImpl.when( callsTo("createList",MockEntity) ).alwaysReturn( new List<MockEntity>() );

      return dao.findAll().then( (list) {
        daoImpl.calls("createList",anything).verify( happenedOnce );
        collection.calls("find").verify( happenedOnce );
        expect( list, new isInstanceOf<List<MockEntity>>("List<MockEntity>") );
        expect( list, equals(dbList) );
      });
    });

    test( "delete() calls Objectory.remove() with correct entity", () {
      
      db.when( callsTo("remove",entity) ).alwaysReturn( new Future.value() );
      
      return dao.delete(entity).then( (_) {
        db.calls("remove",entity).verify( happenedOnce );
      });
    });
    
  }); 

  group( "ObjectoryModelEntity:", () {

    var entity;

    setUp( () {
      entity = new TestModelEntity("dbType");
    });

    test( "dbType returns dbType given in constructor", () {
      expect( entity.dbType, equals("dbType") );
    });

    test( "get:uniqueId returns the ObjectId as an hex string", () {
      var objId = new ObjectId();
      
      entity.id = objId;
 
      expect( entity.uniqueId, new isInstanceOf<String>("String") );
      expect( entity.uniqueId, equals(objId.toHexString()) );
    });
    
  }); 
}
