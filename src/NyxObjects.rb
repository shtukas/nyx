# encoding: UTF-8

$NyxObjectsCache76DBF964 = {}

class NyxObjects2

    # NyxObjects2::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Objects.sqlite3"
    end

    # NyxObjects2::getAllObjects()
    def self.getAllObjects()
        db = SQLite3::Database.new(NyxObjects2::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from table2" , [] ) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # NyxObjects2::put(object)
    def self.put(object)
        db = SQLite3::Database.new(NyxObjects2::databaseFilepath())
        db.transaction 
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into table2 (_setuuid_, _objectuuid_, _object_) values ( ?, ?, ? )", [object["nyxNxSet"], object["uuid"], JSON.generate(object)]
        db.commit 
        db.close
        $NyxObjectsCache76DBF964[object["uuid"]] = object
        Patricia::updateSearchLookupDatabase(object)
    end

    # NyxObjects2::getOrNull(uuid)
    def self.getOrNull(uuid)
        $NyxObjectsCache76DBF964[uuid]
    end

    # NyxObjects2::getSet(setid)
    def self.getSet(setid)
        db = SQLite3::Database.new(NyxObjects2::databaseFilepath())
        db.results_as_hash = true
        answer = []
        db.execute( "select * from table2 where _setuuid_=?" , [setid] ) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # NyxObjects2::destroy(object)
    def self.destroy(object)
        db = SQLite3::Database.new(NyxObjects2::databaseFilepath())
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.close
        $NyxObjectsCache76DBF964.delete(object["uuid"])
        SelectionLookupDatabaseIO::removeRecordsAgainstObject(object["uuid"])
    end
end

NyxObjects2::getAllObjects().each{|object|
    $NyxObjectsCache76DBF964[object["uuid"]] = object
}
