
# encoding: UTF-8

$LibrarianObjects = nil

$TheGreatLibrarianCachePrefix = nil

class Librarian

    # Librarian::getTheGreatLibrarianCachePrefix()
    def self.getTheGreatLibrarianCachePrefix()
        if $TheGreatLibrarianCachePrefix.nil? then
            $TheGreatLibrarianCachePrefix = XCache::getOrNull("TheGreatLibrarianCachePrefix-08b7-4327-a226-b9d29a876888")
        end
        if $TheGreatLibrarianCachePrefix.nil? then
            $TheGreatLibrarianCachePrefix = SecureRandom.hex
            XCache::set("TheGreatLibrarianCachePrefix-08b7-4327-a226-b9d29a876888", $TheGreatLibrarianCachePrefix)
        end
        $TheGreatLibrarianCachePrefix
    end

    # Librarian::eventInternalDispatch(event)
    # When a new object is created, we event log it and also internal dispatch it
    def self.eventInternalDispatch(event)

        if event["mikuType"] == "NxFlotille" then
            return
        end

        if event["mikuType"] == "TxFlt" then
            return
        end

        if event["mikuType"] == "NxDeleted" then
            object = Librarian::getObjectByUUIDOrNull(event["uuid"]) # calling this is the only way to get the mikuType
            if object then
                XCacheSets::destroy("#{Librarian::getTheGreatLibrarianCachePrefix()}:objects-by-mikuType:#{object["mikuType"]}", event["uuid"])
            end
            XCache::destroy("#{Librarian::getTheGreatLibrarianCachePrefix()}:object-by-uuid:#{event["uuid"]}")
            return
        end

        # Generic get by uuid
        XCache::set("#{Librarian::getTheGreatLibrarianCachePrefix()}:object-by-uuid:#{event["uuid"]}", JSON.generate(event))
        
        # Generic get by mikuType
        XCacheSets::set("#{Librarian::getTheGreatLibrarianCachePrefix()}:objects-by-mikuType:#{event["mikuType"]}", event["uuid"], event)

        if event["mikuType"] == "Ax1Text" then
            return
        end

        if event["mikuType"] == "NxAnniversary" then
            return
        end

        if event["mikuType"] == "NxArrow" then
            return
        end

        if event["mikuType"] == "NxBankOp" then
            return
        end

        if event["mikuType"] == "NxCollection" then
            return
        end

        if event["mikuType"] == "NxDataNode" then
            return
        end

        if event["mikuType"] == "NxDNSU" then
            return
        end

        if event["mikuType"] == "NxFrame" then
            return
        end

        if event["mikuType"] == "NxPerson" then
            return
        end

        if event["mikuType"] == "NxRelation" then
            return
        end

        if event["mikuType"] == "NxShip" then
            return
        end

        if event["mikuType"] == "NxTimeline" then
            return
        end

        if event["mikuType"] == "TxDated" then
            return
        end

        if event["mikuType"] == "TxFrame" then
            return
        end

        if event["mikuType"] == "TxTodo" then
            return
        end

        if event["mikuType"] == "Wave" then
            return
        end

        raise "(error) I don't know how to process event: #{JSON.pretty_generate(event)}"
    end

    # Librarian::digestLogFromScratch()
    def self.digestLogFromScratch()
        puts "(reset librarian prefix)"
        XCache::set("TheGreatLibrarianCachePrefix-08b7-4327-a226-b9d29a876888", SecureRandom.hex)
        
        puts "(load events)"
        events  = EventLog::getLogEvents()

        puts "(events to cliques)"
        cliques = EventLog::eventsToCliques(events)

        puts "(cliques to items)"
        items   = EventLog::cliquesToItems(cliques)

        puts "(processing items)"
        items.each{|item|
            puts JSON.pretty_generate(item)
            Librarian::eventInternalDispatch(item)
        }
    end

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        #puts "Librarian::getObjectsByMikuType(#{mikuType})"
        XCacheSets::values("#{Librarian::getTheGreatLibrarianCachePrefix()}:objects-by-mikuType:#{mikuType}")
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        object = XCache::getOrNull("#{Librarian::getTheGreatLibrarianCachePrefix()}:object-by-uuid:#{uuid}")
        if object then
            JSON.parse(object)
        else
            nil
        end
    end

    # ---------------------------------------------------
    # Objects Writing

    # Librarian::commit(object)
    def self.commit(object)
        raise "(error: b18a080c-af1b-4411-bf65-1b528edc6121, missing attribute uuid)" if object["uuid"].nil?
        raise "(error: 60eea9fc-7592-47ad-91b9-b737e09b3520, missing attribute mikuType)" if object["mikuType"].nil?
        EventLog::commit(object)
        Librarian::eventInternalDispatch(object)
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted",
        }
        EventLog::commit(item)
        Librarian::eventInternalDispatch(item)
    end
end
