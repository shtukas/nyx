
# encoding: UTF-8

class Librarian

    # --------------------------------------------------------------
    # Fx18 Adaptation

    # Librarian::destroyFx18Logically(uuid)
    def self.destroyFx18Logically(uuid)
        SystemEvents::sendEventToSQSStage1({
            "uuid"     => uuid,
            "variant"  => SecureRandom.uuid,
            "mikuType" => "NxDeleted",
        })
        SystemEvents::processEvent({
            "mikuType"        => "(object has been deleted)",
            "deletedUUID"     => uuid,
            "deletedMikuType" => mikuType
        }, true)
    end

    # Librarian::mikuTypes(shouldComputeFromScratch = false)
    def self.mikuTypes(shouldComputeFromScratch = false)
        mikuTypes = XCacheSets::values("mikuTypes:a52acbf5")
        if mikuTypes.empty? or shouldComputeFromScratch  then
            XCacheSets::empty("mikuTypes:a52acbf5")
            puts "computing mikuTypes index from scratch"
            Fx18Xp::fx18Filepaths().each{|filepath|
                puts "computing mikuTypes index from scratch, filepath: #{filepath}"
                mikuType = Fx18s::getAttributeOrNull2(filepath, "mikuType")
                XCacheSets::set("mikuTypes:a52acbf5", mikuType, mikuType)
            }
            mikuTypes = XCacheSets::values("mikuTypes:a52acbf5")
        end
        mikuTypes
    end

    # Librarian::mikuTypeUUIDs(mikuType, shouldComputeFromScratch = false)
    def self.mikuTypeUUIDs(mikuType, shouldComputeFromScratch = false)
        uuids = XCacheSets::values("Efd9646f3766:#{mikuType}")
        if uuids.empty? or shouldComputeFromScratch then
            XCacheSets::empty("Efd9646f3766:#{mikuType}")
            Fx18Xp::fx18Filepaths().each{|filepath|
                puts "Librarian::mikuTypeUUIDs, mikuType: #{mikuType}, filepath: #{filepath}"
                m = Fx18s::getAttributeOrNull2(filepath, "mikuType")
                next if m != mikuType
                uuid = Fx18s::getAttributeOrNull2(filepath, "uuid")
                XCacheSets::set("Efd9646f3766:#{mikuType}", uuid, uuid)
            }
            uuids = XCacheSets::values("Efd9646f3766:#{mikuType}")
        end
        uuids
    end

    # Librarian::countObjectsByMikuType(mikuType)
    def self.countObjectsByMikuType(mikuType)
        Librarian::mikuTypeUUIDs(mikuType).count
    end

    # Librarian::processEvent(event)
    def self.processEvent(event)
        if event["mikuType"] == "(object has a new mikuType)" then
            objectuuid = event["objectuuid"]
            objectMikuType = event["objectMikuType"]

            # Update the set of mikuTypes to ensure this one is in there 
            XCacheSets::set("mikuTypes:a52acbf5", objectMikuType, objectMikuType)

            # Remove the objectuuid from all the sets
            Librarian::mikuTypes().each{|mikuType|
                XCacheSets::destroy("Efd9646f3766:#{mikuType}", objectuuid, objectuuid)
            }

            # add the objectuuid into the right set
            XCacheSets::set("Efd9646f3766:#{objectMikuType}", objectuuid, objectuuid)
        end
    end
end
