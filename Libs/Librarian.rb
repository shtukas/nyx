
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

    # Librarian::countObjectsByMikuType(mikuType)
    def self.countObjectsByMikuType(mikuType)
        count = nil
        $librarian_database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select count(*) as _count_ from _objects_ where _mikuType_=?", [mikuType]) do |row|
                count = row['_count_']
            end
            db.close
        }
        count
    end

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        objects = []
        $librarian_database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
                object = JSON.parse(row['_object_'])
                if object["variant"].nil? then
                    object["variant"] = row['_variant_']
                end
                objects << object
            end
            db.close
        }
        objects
    end

    # Librarian::getClique(uuid)
    def self.getClique(uuid) 
        answer = []
        $librarian_database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
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

    # Librarian::getObjectByVariantOrNull(variant)
    def self.getObjectByVariantOrNull(variant)
        object = nil
        $librarian_database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.busy_timeout = 117
            db.busy_handler { |count| true }
            db.results_as_hash = true
            db.execute("select * from _objects_ where _variant_=?", [variant]) do |row|
                object = JSON.parse(row['_object_'])
                if object["variant"].nil? then
                    object["variant"] = row['_variant_']
                end
            end
            db.close
        }
        object
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commit(object)
    def self.commit(object)
        # Do not internal event broadcast from inside this function

        raise "(error: 22533318-f031-44ef-ae10-8b36e0842223, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        object["variant"] = SecureRandom.uuid

        if object["lxGenealogyAncestors"].nil? then
            object["lxGenealogyAncestors"] = []
        end

        object["lxGenealogyAncestors"] << SecureRandom.uuid

        $librarian_database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            #db.execute "delete from _objects_ where _variant_=?", [object["variant"]]
            db.execute "insert into _objects_ (_uuid_, _variant_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["uuid"], object["variant"], object["mikuType"], JSON.generate(object)]
            db.close
        }

        ExternalEvents::sendEventToSQSStage1(object)
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
end
