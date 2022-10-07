
# encoding: UTF-8

class MikuTypedObjects

    # mikutyped-objects.sqlite3 
    # create table _objects_ (_uuid_ text, _mikuType_ text, _object_ text)

    # MikuTypedObjects::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate/mikutyped-objects.sqlite3"
    end

    # MikuTypedObjects::objects(mikuType)
    def self.objects(mikuType)
        db = SQLite3::Database.new(MikuTypedObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objects = []
        db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
            objects << JSON.parse(row["_object_"])
        end
        db.close
        objects
    end

    # MikuTypedObjects::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        db = SQLite3::Database.new(MikuTypedObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        object = nil
        db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
            object = JSON.parse(row["_object_"])
        end
        db.close
        object
    end

    # MikuTypedObjects::set(object)
    def self.set(object)
        if object["uuid"].nil? then
            raise "(error: e8997aeb-c3d8-4241-95d5-303fa99de878) missing attribute uuid, object: #{object}"
        end
        if object["mikuType"].nil? then
            raise "(error: daffb609-c40f-475b-a9d2-9bfea1743ad7) missing attribute mikuType, object: #{object}"
        end
        db = SQLite3::Database.new(MikuTypedObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _objects_ where _uuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_uuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "mikutyped-objects-set",
            "object"   => object,
        })
        nil
    end

    # MikuTypedObjects::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new(MikuTypedObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _objects_ where _uuid_=?", [uuid]
        db.close
        SystemEvents::broadcast({
            "mikuType" => "mikutyped-objects-destroy",
            "uuid"     => uuid,
        })
        nil
    end
end
