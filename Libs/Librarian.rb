
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
        $database_semaphore.synchronize {
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

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        objects = []
        $database_semaphore.synchronize {
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
        $database_semaphore.synchronize {
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

    # Librarian::getObjectByUUIDOrNullEnforceUnique(uuid)
    def self.getObjectByUUIDOrNullEnforceUnique(uuid)
        clique = Librarian::getClique(uuid)
        if clique.size <= 1 then
            return clique.first # covers the empty case (nil) and the 1 case (object)
        end
        Cliques::reduceLocalCliqueToOne(uuid)
    end

    # Librarian::getObjectByVariantOrNull(variant)
    def self.getObjectByVariantOrNull(variant)
        object = nil
        $database_semaphore.synchronize {
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

    # Librarian::commitIdentical(object)
    def self.commitIdentical(object)
        # Do not internal event broadcast from inside this function

        raise "(error: 22533318-f031-44ef-ae10-8b36e0842223, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?
        $database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.execute "delete from _objects_ where _variant_=?", [object["variant"]]
            db.execute "insert into _objects_ (_uuid_, _variant_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["uuid"], object["variant"], object["mikuType"], JSON.generate(object)]
            db.close
        }
        Cliques::garbageCollectLocalCliqueAutomatic(object["uuid"])
    end

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

        $database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            #db.execute "delete from _objects_ where _variant_=?", [object["variant"]]
            db.execute "insert into _objects_ (_uuid_, _variant_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["uuid"], object["variant"], object["mikuType"], JSON.generate(object)]
            db.close
        }

        EventsToCentral::publish(object)
        EventsToAWSQueue::publish(object)
        Cliques::reduceLocalCliqueToOne(object["uuid"])
    end

    # --------------------------------------------------------------
    # Object destroy

    # Librarian::destroyVariantNoEvent(variant)
    def self.destroyVariantNoEvent(variant)
        $database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.execute "delete from _objects_ where _variant_=?", [variant]
            db.close
        }
    end

    # Librarian::destroyCliqueNoEvent(uuid)
    def self.destroyCliqueNoEvent(uuid)
        $database_semaphore.synchronize {
            db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
            db.execute "delete from _objects_ where _uuid_=?", [uuid]
            db.close
        }
    end

    # Librarian::destroyClique(uuid)
    def self.destroyClique(uuid)
        objects = Librarian::getClique(uuid)
        return if objects.empty?
        mikuType = objects[0]["mikuType"]
        Librarian::destroyCliqueNoEvent(uuid)
        lxGenealogyAncestors = objects.map{|object| object["lxGenealogyAncestors"] }.flatten + [SecureRandom.uuid]
        event = {
            "uuid"     => uuid,
            "variant"  => SecureRandom.uuid,
            "mikuType" => "NxDeleted",
            "lxGenealogyAncestors" => lxGenealogyAncestors
        }
        EventsToCentral::publish(event)
        EventsToAWSQueue::publish(event)
        EventsInternal::broadcast({
            "mikuType"        => "(object has been deleted)",
            "deletedUUID"     => uuid,
            "deletedMikuType" => mikuType
        })
    end

    # --------------------------------------------------------------
    # Incoming Events

    # Librarian::incomingDatabaseObject(event, source)
    def self.incomingDatabaseObject(event, source)
        if event["mikuType"] == "NxDeleted" then
            Librarian::destroyCliqueNoEvent(event["uuid"])
            return
        end

        if !Librarian::getObjectByVariantOrNull(event["variant"]) then
            if source then
                puts "Librarian, incoming event (#{source}): #{JSON.pretty_generate(event)}".green
            end
            Librarian::commitIdentical(event)
        end

        EventsInternal::broadcast(event)
    end

    # --------------------------------------------------------------
    # Data Maintenance

    # Librarian::maintenance()
    def self.maintenance()

        Librarian::getObjectsByMikuType("NxBankOp").each{|item|
            if (Time.new.to_i - item["unixtime"]) > 86400*30 then
                puts JSON.pretty_generate(item)
                Librarian::destroyVariantNoEvent(item["variant"])
            end
        }

        if File.exists?(StargateCentral::pathToCentral()) then
            StargateCentralObjects::getObjectsByMikuType("NxBankOp").each{|item|
                if (Time.new.to_i - item["unixtime"]) > 86400*30 then
                    puts JSON.pretty_generate(item)
                    StargateCentralObjects::destroyVariantNoEvent(item["variant"])
                end
            }
        end

        Librarian::getObjectsByMikuType("NxDNSU").each{|item|
            if item["targetunixtime"] < Time.new.to_i then
                puts JSON.pretty_generate(item)
                Librarian::destroyVariantNoEvent(item["variant"])
            end
        }

        if File.exists?(StargateCentral::pathToCentral()) then
            StargateCentralObjects::getObjectsByMikuType("NxDNSU").each{|item|
                if item["targetunixtime"] < Time.new.to_i then
                    puts JSON.pretty_generate(item)
                    StargateCentralObjects::destroyVariantNoEvent(item["variant"])
                end
            }
        end
    end
end
