
# encoding: UTF-8

class Phage

    # phage.sqlite3
    # create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);

    # Phage::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Instance-Databases/#{Config::get("instanceId")}/phage.sqlite3"
    end

    # GETTERS

    # Phage::variantsProjection(objects)
    def self.variantsProjection(objects)
        higestOfTwo = lambda {|o1Opt, o2|
            if o1Opt.nil? then
                return o2
            end
            o1 = o1Opt
            if o1["phage_time"] < o2["phage_time"] then
                o2
            else
                o1
            end
        }
        projection = {}
        objects.each{|object|
            next if !object["phage_alive"]
            projection[object["uuid"]] = higestOfTwo.call(projection[object["uuid"]], object)
        }
        projection.values
    end

    # Phage::variantsForMikuType(mikuType)
    def self.variantsForMikuType(mikuType)
        db = SQLite3::Database.new(Phage::pathToDatabase())
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

    # Phage::getVariantsForUUID(uuid)
    def self.getVariantsForUUID(uuid)
        db = SQLite3::Database.new(Phage::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        objects = nil
        db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
            objects << JSON.parse(row["_object_"])
        end
        db.close
        objects
    end

    # Phage::objects(mikuType)
    def self.objects(mikuType)
        Phage::variantsProjection(Phage::variantsForMikuType(mikuType))
    end

    # Phage::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = Phage::variantsProjection(Phage::getVariantsForUUID(uuid))
        # The number of objects should be zero or one
        if objects.size > 1 then
            raise "(error: 1de85ac2-1788-448c-929f-e9d8e4d913df) unusual number of objects found for uuid: #{uuid}, found #{objects.size}"
        end
        objects.first
    end

    # SETTERS

    # Phage::commit(object)
    def self.commit(object)
        # TODO: this is temporary the time to migrate all objects
        object["phage_uuid"] = SecureRandom.uuid
        object["phage_time"] = Time.new.to_f
        FileSystemCheck::fsck_PhageItem(object, SecureRandom.hex, false)
        db = SQLite3::Database.new(Phage::pathToDatabase())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _objects_ (_phage_uuid_, _uuid_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["phage_uuid"], object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
        nil
    end

    # DESTROY

    # Phage::destroy(uuid)
    def self.destroy(uuid)
        # We extract the latest variant, if there is any, and flip it
        object = Phage::getObjectOrNull(uuid)
        return if object.nil?
        object["phage_alive"] = false
        Phage::commit(object)
    end
end
