
# encoding: UTF-8

class Librarian

    # Librarian::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/objects.sqlite3"
    end

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::objects()
    def self.objects()
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
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
        #puts "Librarian::getObjectsByMikuType(#{mikuType})"
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _objects_ where _mikuType_=?", [mikuType]) do |row|
            answer << JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _objects_ where _uuid_=?", [uuid]) do |row|
            answer = JSON.parse(row['_object_'])
        end
        db.close
        answer
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commitNoEvent(object)
    def self.commitNoEvent(object)
        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        if object["lxGenealogyAncestors"].nil? then
            object["lxGenealogyAncestors"] = []
        else
            object["lxGenealogyAncestors"] << SecureRandom.hex(4)
        end

        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _uuid_=?", [object["uuid"]]
        db.execute "insert into _objects_ (_uuid_, _mikuType_, _object_) values (?, ?, ?)", [object["uuid"], object["mikuType"], JSON.generate(object)]
        db.close

        object
    end

    # Librarian::commit(object)
    def self.commit(object)
        object = Librarian::commitNoEvent(object)
        #puts JSON.pretty_generate(object)
        EventsLocalToCentralInbox::publish(object)
        EventsLocalToMachine::publish(object)
    end

    # --------------------------------------------------------------
    # Object destroy

    # Librarian::destroyNoEvent(uuid)
    def self.destroyNoEvent(uuid)
        db = SQLite3::Database.new(Librarian::pathToDatabaseFile())
        db.execute "delete from _objects_ where _uuid_=?", [uuid]
        db.close
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyNoEvent(uuid)
        event = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted",
        }
        EventsLocalToCentralInbox::publish(event)
        EventsLocalToMachine::publish(event)
    end

    # --------------------------------------------------------------
    # Incoming Events

    # Librarian::incomingEventFromOutside(event)
    def self.incomingEventFromOutside(event)

        puts "Librarian::incomingEventFromOutside, event: #{JSON.pretty_generate(event)}"

        if event["mikuType"] == "NxDeleted" then
            Librarian::destroyNoEvent(event["uuid"])
            return
        end

        existingObject = Librarian::getObjectByUUIDOrNull(event["uuid"])

        puts "existingObject: #{JSON.pretty_generate(existingObject)}"

        if existingObject.nil? then
            puts "existing object is null, commiting event"
            # That's the easy case
            Librarian::commitNoEvent(event)

            # And we also know that the two below special incomings are for that kind.
            Bank::incomingEventFromOutside(event)
            DoNotShowUntil::incomingEventFromOutside(event)
            return
        end

        if Genealogy::object1ShouldBeReplacedByObject2(existingObject, event) then
            puts "existing object is being replaced by event"
            Librarian::commitNoEvent(event)
            return
        end

        if Genealogy::object1IsAncestrorOfObject2(event, existingObject) then
            return
        end

        if existingObject.to_s == event.to_s then
            puts "existing object and event are equal"
            return
        end

        objxp1 = existingObject.clone
        objxp1.delete("lxGenealogyAncestors")
        objxp2 = event.clone
        objxp2.delete("lxGenealogyAncestors")

        if objxp1.to_s == objxp2.to_s then
            puts "existing object and event have same content, but incompatible genealogies"
            puts "extending"
            existingObject["lxGenealogyAncestors"] = (existingObject["lxGenealogyAncestors"] + event["lxGenealogyAncestors"]).uniq
            Librarian::commitNoEvent(existingObject)
            return
        end

        puts "We have a conflict that cannot be automatially resolved. Select the one to keep"
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", ["existing", "event"])
        return if option.nil?
        if option == "existing" then
            return
        end
        if option == "event" then
            puts "replacing existing object by event"
            Librarian::commitNoEvent(event)
            return
        end
    end

    # Librarian::getObjectsFromCentral()
    def self.getObjectsFromCentral()
        StargateCentralObjects::objects().each{|object|
            Librarian::incomingEventFromOutside(object)
        }
    end

end
