
# encoding: UTF-8

class MikuTypedObjects

    # mikutyped-objects.sqlite3 
    # create table _objects_ (_uuid_ text, _mikuType_ text, _object_ text)

    # MikuTypedObjects::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Instance-Databases/#{Config::get("instanceId")}/mikutyped-objects.sqlite3"
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

    # MikuTypedObjects::commit(object)
    def self.commit(object)
        object["phage_uuid"] = SecureRandom.uuid
        object["phage_time"] = Time.new.to_f
        FileSystemCheck::fsck_PhageItem(object, SecureRandom.hex, false)
        db = SQLite3::Database.new(MikuTypedObjects::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "delete from _objects_ where _uuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_uuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
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
        nil
    end
end
