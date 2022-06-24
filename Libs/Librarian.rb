
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
        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
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

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
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

    # Librarian::getClique(uuid)
    def self.getClique(uuid) 
        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
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

    # Librarian::getObjectByUUIDOrNullEnforceUnique(uuid)
    def self.getObjectByUUIDOrNullEnforceUnique(uuid)
        clique = Librarian::getClique(uuid)
        if clique.empty? then
            return nil
        end
        if clique.size == 1 then
            return clique[0]
        end
        raise "(error: 32a9fa87-cf35-4538-8e12-4a29ffc56398) You need to implement this"
    end

    # Librarian::getObjectByVariantOrNull(variant)
    def self.getObjectByVariantOrNull(variant)
        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        object = nil
        db.execute("select * from _objects_ where _variant_=?", [variant]) do |row|
            object = JSON.parse(row['_object_'])
        end
        db.close
        object
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commitNoEvent(object)
    def self.commitNoEvent(object)
        raise "(error: 22533318-f031-44ef-ae10-8b36e0842223, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        object["variant"] = SecureRandom.uuid

        if object["lxGenealogyAncestors"].nil? then
            object["lxGenealogyAncestors"] = []
        end

        object["lxGenealogyAncestors"] << SecureRandom.uuid

        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
        #db.execute "delete from _objects_ where _variant_=?", [object["variant"]]
        db.execute "insert into _objects_ (_uuid_, _variant_, _mikuType_, _object_) values (?, ?, ?, ?)", [object["uuid"], object["variant"], object["mikuType"], JSON.generate(object)]
        db.close

        object
    end

    # Librarian::commit(object)
    def self.commit(object)
        object = Librarian::commitNoEvent(object)
        #puts JSON.pretty_generate(object)
        EventsToCentral::publish(object)
        EventsToAWSQueue::publish(object)
        Cliques::garbageCollectLocalClique(object["uuid"])
    end

    # --------------------------------------------------------------
    # Object destroy

    # Librarian::destroyVariantNoEvent(variant)
    def self.destroyVariantNoEvent(variant)
        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
        db.execute "delete from _objects_ where _variant_=?", [variant]
        db.close
    end

    # Librarian::destroyCliqueNoEvent(uuid)
    def self.destroyCliqueNoEvent(uuid)
        db = SQLite3::Database.new(Librarian::pathToObjectsDatabaseFile())
        db.execute "delete from _objects_ where _uuid_=?", [uuid]
        db.close
    end

    # Librarian::destroyClique(uuid)
    def self.destroyClique(uuid)
        objects = Librarian::getClique(uuid)
        return if objects.empty?
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
    end

    # --------------------------------------------------------------
    # Incoming Events

    # Librarian::incomingEvent(event, source)
    def self.incomingEvent(event, source)
        if event["mikuType"] == "NxDeleted" then
            Librarian::destroyCliqueNoEvent(event["uuid"])
            return
        end
        return if Librarian::getObjectByVariantOrNull(event["variant"]) # we already have this variant
        puts "Librarian, incoming event (#{source}): #{JSON.pretty_generate(event)}".green

        if Machines::isLucille20() then
            FileSystemCheck::fsckLibrarianMikuObjectExitAtFirstFailure(event, EnergyGridElizabeth.new())
        end

        Librarian::commitNoEvent(event)
        Cliques::garbageCollectLocalClique(event["uuid"])
        DoNotShowUntil::incomingEvent(event)
        Bank::incomingEvent(event)
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
