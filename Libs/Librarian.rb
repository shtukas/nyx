
# encoding: UTF-8

class Librarian

    # Librarian::pathToObjectsDatabaseFile()
    def self.pathToObjectsDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/objects.sqlite3"
    end

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::objects()
    def self.objects()
        answer = []
        $librarian_database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _objects_") do |row|
                object = JSON.parse(row['_object_'])
                if object["variant"].nil? then
                    object["variant"] = row['_variant_']
                end
                answer << object
            end
            db.close
        }
        answer
    end

    # --------------------------------------------------------------
    # Object destroy

    # Librarian::destroyEntity(uuid)
    def self.destroyEntity(uuid)
        ExternalEvents::sendEventToSQSStage1({
            "uuid"     => uuid,
            "variant"  => SecureRandom.uuid,
            "mikuType" => "NxDeleted",
            "lxGenealogyAncestors" => lxGenealogyAncestors
        })
        InternalEvents::broadcast({
            "mikuType"        => "(object has been deleted)",
            "deletedUUID"     => uuid,
            "deletedMikuType" => mikuType
        })
    end

    # --------------------------------------------------------------
    # Fx18 Interface

    # Librarian::mikuTypes(shouldComputeFromScratch = false)
    def self.mikuTypes(shouldComputeFromScratch = false)
        setuuid = "mikuTypes:a52acbf5"
        mikuTypes = XCacheSets::values(setuuid)
        if mikuTypes.empty? or shouldComputeFromScratch  then
            puts "computing mikuTypes index from scratch"
            Fx18Xp::fx18Filepaths().each{|filepath|
                puts "computing mikuTypes index from scratch, filepath: #{filepath}"
                mikuType = Fx18s::getAttributeOrNull2(filepath, "mikuType")
                XCacheSets::set(setuuid, mikuType, mikuType)
            }
            mikuTypes = XCacheSets::values(setuuid)
        end
        mikuTypes
    end

    # Librarian::mikuTypeUUIDs(mikuType, shouldComputeFromScratch = false)
    def self.mikuTypeUUIDs(mikuType, shouldComputeFromScratch = false)
        setuuid = "Efd9646f3766:#{mikuType}"
        uuids = XCacheSets::values(setuuid)
        if uuids.empty? or shouldComputeFromScratch then
            Fx18Xp::fx18Filepaths().each{|filepath|
                puts "Librarian::mikuTypeUUIDs, mikuType: #{mikuType}, filepath: #{filepath}"
                m = Fx18s::getAttributeOrNull2(filepath, "mikuType")
                next if m != mikuType
                uuid = Fx18s::getAttributeOrNull2(filepath, "uuid")
                XCacheSets::set(setuuid, uuid, uuid)
            }
            uuids = XCacheSets::values(setuuid)
        end
        uuids
    end

    # Librarian::countObjectsByMikuType(mikuType)
    def self.countObjectsByMikuType(mikuType)
        Librarian::mikuTypeUUIDs(mikuType).count
    end
end
