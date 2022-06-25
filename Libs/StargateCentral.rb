class StargateCentral

    # StargateCentral::pathToCentral()
    def self.pathToCentral()
        "/Volumes/Infinity/Data/Pascal/Stargate-Central"
    end
end

class StargateCentralObjects

    # StargateCentralObjects::pathToObjectsDatabase()
    def self.pathToObjectsDatabase()
        "#{StargateCentral::pathToCentral()}/objects.sqlite3"
    end

    # StargateCentralObjects::objects()
    def self.objects()
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_") do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # StargateCentralObjects::commit(object)
    def self.commit(object)
        raise "(error: ee5c0d42-685e-433a-9d5b-c043494f19ff, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: a98ef432-f4f5-43e2-82ba-2edafa505a8d, missing attribute mikuType)" if object["mikuType"].nil?

        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.execute "delete from _objects_ where _variant_=?", [object["variant"]]
        db.execute "insert into _objects_ (_uuid_, _variant_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["uuid"], object["variant"], object["mikuType"], JSON.generate(object)]
        db.close

        Cliques::garbageCollectCentralClique(object["uuid"])
    end

    # StargateCentralObjects::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objects = []
        db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
            objects << JSON.parse(row['_object_'])
        end
        db.close
        objects
    end

    # StargateCentralObjects::getClique(uuid)
    def self.getClique(uuid) 
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # StargateCentralObjects::destroyVariantNoEvent(variant)
    def self.destroyVariantNoEvent(variant)
        db = SQLite3::Database.new(StargateCentralObjects::pathToObjectsDatabase())
        db.execute "delete from _objects_ where _variant_=?", [variant]
        db.close
    end
end
