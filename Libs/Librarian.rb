
# encoding: UTF-8

$LibrarianObjects = nil

class Librarian

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::pathToDatabaseFile()
    def self.pathToDatabaseFile()
        "/Users/pascal/Galaxy/DataBank/Stargate/objects-store.sqlite3"
    end

    # Librarian::objects()
    def self.objects()
        if $LibrarianObjects.nil? then
            puts "> #{Time.new.to_s}: load events"
            events  = EventLog::getLogEvents()

            puts "> #{Time.new.to_s}: build cliques"
            cliques = EventLog::eventsToCliques(events)

            puts "> #{Time.new.to_s}: build items"
            items   = EventLog::cliquesToItems(cliques)

            $LibrarianObjects = items
        end
        $LibrarianObjects.map{|item| item.clone }
    end

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        Librarian::objects().select{|item| item["mikuType"] == mikuType }
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        Librarian::objects().select{|item| item["uuid"] == uuid }.first
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commit(object)
    def self.commit(object)

        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?

        items = Librarian::objects().reject{|item| item["uuid"] == object["uuid"] }
        $LibrarianObjects = items + [object]

        EventLog::commit(object)
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        items = Librarian::objects().reject{|item| item["uuid"] == uuid }
        $LibrarianObjects = items

        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxDeleted",
        }
        EventLog::commit(item)
    end
end
