
# encoding: UTF-8

class Phage

    # phage.sqlite3
    # create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);

    # UTILS

    # Phage::variantsToUniqueVariants(variants)
    def self.variantsToUniqueVariants(variants)
        answer = []
        phage_uuids_recorded = {}
        variants.each{|variant|
            next if phage_uuids_recorded[variant["phage_uuid"]]
            answer << variant
            phage_uuids_recorded[variant["phage_uuid"]] = true
        }
        answer
    end

    # Phage::variantsToObjectsUUIDed(objects)
    def self.variantsToObjectsUUIDed(objects)
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

    # DATABASES

    # Phage::databasesPathsForReading()
    def self.databasesPathsForReading()
        LucilleCore::locationsAtFolder("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Phage")
            .select{|filepath| filepath[-8, 8] == ".sqlite3" }
    end

    # Phage::databasePathForWriting()
    def self.databasePathForWriting()
        instanceId = Config::get("instanceId")
        filepath = "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Phage/phage-#{CommonUtils::today()}-#{instanceId}.sqlite3"
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.execute("create table _objects_ (_phage_uuid_ text primary key, _uuid_ text, _mikuType_ text, _object_ text);")
            db.close
        end
        filepath
    end

    # SETTERS (1)

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

    # VARIANTS

    # Phage::variantsEnumerator()
    def self.variantsEnumerator()
        Enumerator.new do |variants|
            Phage::databasesPathsForReading().each{|filepath|
                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_", []) do |row|
                    variants << JSON.parse(row["_object_"])
                end
                db.close
            }
        end
    end

    # Phage::newIshVariantsOnChannelEnumerator(channelId)
    def self.newIshVariantsOnChannelEnumerator(channelId)

        getFileIsDoneForChannel = lambda {|channelId, filepath, mtime|
            XCache::getFlag("6624f97b-6e92-4094-b2e7-3ba66f886edb:#{channelId}:#{filepath}:#{mtime.to_s}")
        }

        setFileIsDoneForChannel = lambda {|channelId, filepath, mtime|
            XCache::setFlag("6624f97b-6e92-4094-b2e7-3ba66f886edb:#{channelId}:#{filepath}:#{mtime.to_s}", true)
        }

        Enumerator.new do |variants|
            Phage::databasesPathsForReading().each{|filepath|
                mtime = File.mtime(filepath)
                next if getFileIsDoneForChannel.call(channelId, filepath, mtime)

                db = SQLite3::Database.new(filepath)
                db.busy_timeout = 117
                db.busy_handler { |count| true }
                db.results_as_hash = true
                db.execute("select * from _objects_", []) do |row|
                    variants << JSON.parse(row["_object_"])
                end
                db.close

                setFileIsDoneForChannel.call(channelId, filepath, mtime)
            }
        end
    end

end

class PhageRefactoring

    # PhageRefactoring::nx20sTypes()
    def self.nx20sTypes()
        ["NxTodo", "Wave", "NyxNode"]
    end

    # PhageRefactoring::nx20s() # Array[Nx20]
    def self.nx20s()
        phageObjects = PhageRefactoring::objects().select{|object| PhageRefactoring::nx20sTypes().include?(object["mikuType"]) }
        phageObjects
            .map{|object|
                {
                    "announce" => "(#{object["mikuType"]}) #{PolyFunctions::genericDescriptionOrNull(object)}",
                    "unixtime" => object["unixtime"],
                    "item"     => object
                }
            }
    end

    # PhageRefactoring::mikuTypeCount(mikuType) # Integer
    def self.mikuTypeCount(mikuType)
        PhageRefactoring::objectsForMikuType(mikuType).size
    end

    # PhageRefactoring::getVariantsForUUID(uuid)
    def self.getVariantsForUUID(uuid)
        Phage::variantsEnumerator().select{|item| item["uuid"] == uuid }
    end

    # PhageRefactoring::objects()
    def self.objects()
        Phage::variantsToObjectsUUIDed(Phage::variantsEnumerator().to_a)
    end

    # PhageRefactoring::objectsForMikuType(mikuType)
    def self.objectsForMikuType(mikuType)
        Phage::variantsToObjectsUUIDed(PhageAgentMikutypes::mikuTypeToVariants(mikuType))
    end

    # PhageRefactoring::getObjectOrNull(uuid)
    def self.getObjectOrNull(uuid)
        objects = Phage::variantsToObjectsUUIDed(PhageRefactoring::getVariantsForUUID(uuid))
        # The number of objects should be zero or one
        if objects.size > 1 then
            raise "(error: 1de85ac2-1788-448c-929f-e9d8e4d913df) unusual number of objects found for uuid: #{uuid}, found #{objects.size}"
        end
        objects.first
    end

    # PhageRefactoring::setAttribute2(objectuuid, attname, attvalue)
    def self.setAttribute2(objectuuid, attname, attvalue)
        item = PhageRefactoring::getObjectOrNull(objectuuid)
        return if item.nil?
        item[attname] = attvalue
        Phage::commit(item)
    end

    # PhageRefactoring::destroy(uuid)
    def self.destroy(uuid)
        # We extract the latest variant, if there is any, and flip it
        object = PhageRefactoring::getObjectOrNull(uuid)
        return if object.nil?
        object["phage_alive"] = false
        Phage::commit(object)
    end
end

class PhageAgentMikutypes

    # PhageAgentMikutypes::mikuTypeToVariants(mikuType)
    def self.mikuTypeToVariants(mikuType)

        variants = []

        v1s = XCache::getOrNull("19ad36f6-24fb-4ab9-b4bc-1f3aa58cf1d6:#{mikuType}")
        if v1s then
            JSON.parse(v1s).each{|variant|
                variants << variant
            }
        end

        Phage::newIshVariantsOnChannelEnumerator("f7f5e1bb-8154-4f14-a2c4-bb591095c5d1:#{mikuType}")
            .each{|variant|
                next if variant["mikuType"] != mikuType
                variants << variant
            }

        variants = Phage::variantsToUniqueVariants(variants)

        XCache::set("19ad36f6-24fb-4ab9-b4bc-1f3aa58cf1d6:#{mikuType}", JSON.generate(variants))

        variants

    end
end
