
# encoding: UTF-8

class Phage

    # phage.sqlite3
    # create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);

    # Phage::pathToDatabase()
    def self.pathToDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Instance-Databases/#{Config::get("instanceId")}/phage.sqlite3"
    end

    # Phage::databasesPathsForReading()
    def self.databasesPathsForReading()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Phage")
    end

    # Phage::databasePathForWriting()
    def self.databasePathForWriting()
        instanceId = Config::get("instanceId")
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Phage")
            .sort
            .select{|filepath| File.basename(filepath).include?(instanceId) }
            .reverse
            .first
    end

    # GETTERS (variants)

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
            projection[object["uuid"]] = higestOfTwo.call(projection[object["uuid"]], object)
        }
        projection.values.select{|object| object["phage_alive"] }
    end

    # Phage::variants()
    def self.variants()
        objects = []
        Phage::databasesPathsForReading()
            .each{|database_filepath|
                db = SQLite3::Database.new(database_filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_", []) do |row|
                    objects << JSON.parse(row["_object_"])
                end
                db.close
            }
        objects
    end

    # Phage::variantsForMikuType(mikuType)
    def self.variantsForMikuType(mikuType)
        objects = []
        Phage::databasesPathsForReading()
            .each{|database_filepath|
                db = SQLite3::Database.new(database_filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
                    objects << JSON.parse(row["_object_"])
                end
                db.close
            }
        objects
    end

    # Phage::getVariantsForUUID(uuid)
    def self.getVariantsForUUID(uuid)
        objects = []
        Phage::databasesPathsForReading()
            .each{|database_filepath|
                db = SQLite3::Database.new(database_filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
                    objects << JSON.parse(row["_object_"])
                end
                db.close
            }
        objects
    end

    # GETTERS (objects)

    # Phage::objects()
    def self.objects()
        Phage::variantsProjection(Phage::variants())
    end

    # Phage::objectsForMikuType(mikuType)
    def self.objectsForMikuType(mikuType)
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

    # GETTERS (misc)

    # Phage::nx20sTypes()
    def self.nx20sTypes()
        ["NxTodo", "Wave", "NyxNode"]
    end

    # Phage::nx20s() # Array[Nx20]
    def self.nx20s()
        phageObjects = Phage::objects().select{|object| Phage::nx20sTypes().include?(object["mikuType"]) }
        phageObjects
            .map{|object|
                {
                    "announce" => "(#{object["mikuType"]}) #{PolyFunctions::genericDescriptionOrNull(object)}",
                    "unixtime" => object["unixtime"],
                    "item"     => object
                }
            }
    end

    # Phage::mikuTypeCount(mikuType) # Integer
    def self.mikuTypeCount(mikuType)
        Phage::objectsForMikuType(mikuType).size
    end

    # SETTERS

    # Phage::commit(object)
    def self.commit(object)
        # TODO: this is temporary the time to migrate all objects
        object["phage_uuid"] = SecureRandom.uuid
        object["phage_time"] = Time.new.to_f
        FileSystemCheck::fsck_PhageItem(object, SecureRandom.hex, false)
        db = SQLite3::Database.new(Phage::databasePathForWriting())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute "insert into _objects_ (_phage_uuid_, _uuid_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["phage_uuid"], object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close
        nil
    end

    # Phage::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        item = Phage::getObjectOrNull(objectuuid)
        return if item.nil?
        item[attname] = attvalue
        Phage::commit(item)
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
