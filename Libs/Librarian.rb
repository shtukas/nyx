
# encoding: UTF-8

$LibrarianObjects = nil

class Librarian

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::objects()
    def self.objects()
        if $LibrarianObjects.nil? then
            puts "> #{Time.new.to_s}: load events"
            events  = EventLog::getLogEvents()

            puts "> #{Time.new.to_s}: build cliques"
            cliques = EventLog::eventsToCliques(events)

            puts "> #{Time.new.to_s}: build items"
            items   = EventLog::cliquesToItems(cliques)

            $LibrarianObjects = {}
            items.each{|item|

                # NxBankOp are evented, but they go not go into $LibrarianObjects
                # Instead they are sent to $NxBankOpRepository
                if item["mikuType"] == "NxBankOp" then
                    $NxBankOpRepository.incoming(item)
                    next
                end

                # NxDNSU are evented, but they go not go into $LibrarianObjects
                # Instead they are sent to $DoNotShowUntil
                if item["mikuType"] == "NxDNSU" then
                    $DoNotShowUntil.incoming(item)
                    next
                end

                if item["mikuType"] == "NxDeleted" then
                    $LibrarianObjects.delete(item["uuid"])
                    next
                end

                $LibrarianObjects[item["uuid"]] = item
            }
        end
        $LibrarianObjects.values.map{|item| item.clone }
    end

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        Librarian::objects().select{|item| item["mikuType"] == mikuType }
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        if $LibrarianObjects.nil? then
            Librarian::objects() # to build the dataset
        end
        $LibrarianObjects[uuid].clone
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commit(object)
    def self.commit(object)
        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?
        if !$LibrarianObjects.nil? then
            $LibrarianObjects[object["uuid"]] = object.clone
        end
        EventLog::commit(object)
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        if !$LibrarianObjects.nil? then
            $LibrarianObjects.delete(uuid)
        end
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted",
        }
        EventLog::commit(item)
    end
end
