
# encoding: UTF-8

class NxPersonalEvent

    # NxPersonalEvent::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/events.sqlite3"
    end

    # NxPersonalEvent::createNewEvent(uuid, datetime, date, description)
    def self.createNewEvent(uuid, datetime, date, description)
        db = SQLite3::Database.new(NxPersonalEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "insert into _events1_ (_uuid_, _datetime_, _date_, _description_) values (?,?,?,?)", [uuid, datetime, date, description]
        db.close
    end

    # NxPersonalEvent::destroyEvent(uuid)
    def self.destroyEvent(uuid)
        db = SQLite3::Database.new(NxPersonalEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _events1_ where _uuid_=?", [uuid]
        db.close
    end

    # NxPersonalEvent::getNxEventByIdOrNull(id): null or NxEvent
    def self.getNxEventByIdOrNull(id)
        db = SQLite3::Database.new(NxPersonalEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _events1_ where _uuid_=?" , [id] ) do |row|
            answer = {
                "uuid"        => row["_uuid_"],
                "entityType"  => "NxPersonalEvent",
                "datetime"    => row["_datetime_"],
                "date"        => row["_date_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # NxPersonalEvent::interactivelyCreateNewNxEventOrNull()
    def self.interactivelyCreateNewNxEventOrNull()
        uuid = SecureRandom.uuid
        date = LucilleCore::askQuestionAnswerAsString("date (empty to abort): ")
        return nil if date == ""
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxPersonalEvent::createNewEvent(uuid, Time.new.utc.iso8601, date, description)
        NxPersonalEvent::getNxEventByIdOrNull(uuid)
    end

    # NxPersonalEvent::updateDescription(uuid, description)
    def self.updateDescription(uuid, description)
        db = SQLite3::Database.new(NxPersonalEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "update _events1_ set _description_=? where _uuid_=?", [description, uuid]
        db.close
    end

    # NxPersonalEvent::events(): Array[NxEvent]
    def self.events()
        db = SQLite3::Database.new(NxPersonalEvent::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _events1_" , [] ) do |row|
            answer << {
                "entityType"  => "NxListing",
                "uuid"        => row["_uuid_"],
                "datetime"    => row["_datetime_"],
                "date"        => row["_date_"],
                "description" => row["_description_"],
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxPersonalEvent::toString(event)
    def self.toString(event)
        "[event] #{event["description"]}"
    end

    # NxPersonalEvent::selectOneNxEventOrNull()
    def self.selectOneNxEventOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxPersonalEvent::events(), lambda{|event| event["description"] })
    end

    # NxPersonalEvent::architectOneNxEventOrNull()
    def self.architectOneNxEventOrNull()
        event = NxPersonalEvent::selectOneNxEventOrNull()
        return event if event
        NxPersonalEvent::interactivelyCreateNewNxEventOrNull()
    end

    # NxPersonalEvent::landing(event)
    def self.landing(event)
        loop {
            event = NxPersonalEvent::getNxEventByIdOrNull(event["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if event.nil?
            system("clear")

            puts NxPersonalEvent::toString(event).gsub("[event]", "[evnt]").green

            entities = Links::entities(event["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NxEntity::toString(entity)}" }

            puts ""

            puts "update description | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NxEntity::landing(entity)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(event["description"]).strip
                return if description == ""
                NxNode::updateDescription(event["uuid"], description)
            end

            if Interpreting::match("connect", command) then
                NxEntity::linkToOtherArchitectured(event)
            end

            if Interpreting::match("disconnect", command) then
                NxEntity::unlinkFromOther(event)
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy listing ? : ") then
                    NxNode::destroyNx10(event["uuid"])
                end
            end
        }
    end

    # NxPersonalEvent::nx19s()
    def self.nx19s()
        NxPersonalEvent::events().map{|event|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxPersonalEvent::toString(event)}",
                "type"     => "NxPersonalEvent",
                "payload"  => event
            }
        }
    end
end
