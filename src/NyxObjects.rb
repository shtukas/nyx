# encoding: UTF-8

class NyxObjectsCore
    # NyxObjectsCore::nyxNxSets()
    def self.nyxNxSets()
        [
            "b66318f4-2662-4621-a991-a6b966fb4398", # Asteroids
            "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4", # Waves
            "0f555c97-3843-4dfe-80c8-714d837eba69", # NSNode1638
            "e54eefdf-53ea-47b0-a70c-c93d958bbe1c", # TaxonomyItems
            "25bb489f-a25b-46af-938a-96cc42e2694c", # Tags
        ]
    end

    # NyxObjectsCore::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Nyx-Objects.sqlite3"
    end
end

$NyxObjectsCache76DBF964 = {}

class NyxObjects2

    # NyxObjects2::put(object)
    def self.put(object)

        db = SQLite3::Database.new(NyxObjectsCore::databaseFilepath())
        db.transaction 
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.execute "insert into table2 (_setuuid_, _objectuuid_, _object_) values ( ?, ?, ? )", [object["nyxNxSet"], object["uuid"], JSON.generate(object)]
        db.commit 
        db.close

        $NyxObjectsCache76DBF964[object["uuid"]] = object
    end

    # NyxObjects2::getOrNull(uuid)
    def self.getOrNull(uuid)
        $NyxObjectsCache76DBF964[uuid]
    end

    # NyxObjects2::getSet(setid)
    def self.getSet(setid)
        db = SQLite3::Database.new(NyxObjectsCore::databaseFilepath())
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
        db = SQLite3::Database.new(NyxObjectsCore::databaseFilepath())
        db.execute "delete from table2 where _objectuuid_=?", [object["uuid"]]
        db.close
        $NyxObjectsCache76DBF964.delete(object["uuid"])
    end
end

NyxObjectsCore::nyxNxSets().each{|setid|
    NyxObjects2::getSet(setid).each{|object|
        $NyxObjectsCache76DBF964[object["uuid"]] = object
    }
}
