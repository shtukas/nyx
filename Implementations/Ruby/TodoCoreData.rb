

$TodoCoreDataCache76DBF964 = {}

class TodoCoreData

    # TodoCoreData::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/NS-Core-Objects.sqlite3"
    end

    # TodoCoreData::getAllObjects()
    def self.getAllObjects()
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from table2" , [] ) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # TodoCoreData::put(object)
    def self.put(object)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into table2 (_setuuid_, _objectuuid_, _object_) values ( ?, ?, ? )", [object["nyxNxSet"], object["uuid"], JSON.generate(object)]
        db.commit 
        db.close
        $TodoCoreDataCache76DBF964[object["uuid"]] = object
    end

    # TodoCoreData::getOrNull(uuid)
    def self.getOrNull(uuid)
        $TodoCoreDataCache76DBF964[uuid]
    end

    # TodoCoreData::getSet(setid)
    def self.getSet(setid)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from table2 where _setuuid_=?" , [setid]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # TodoCoreData::destroy(object)
    def self.destroy(object)
        db = SQLite3::Database.new(TodoCoreData::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.close
        $TodoCoreDataCache76DBF964.delete(object["uuid"])
        Ordinals::deleteRecord(object["uuid"])
    end
end

TodoCoreData::getAllObjects().each{|object|
    $TodoCoreDataCache76DBF964[object["uuid"]] = object
}
