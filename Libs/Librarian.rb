
# encoding: UTF-8

$TheGreatLibrarianCachePrefix = nil

$MikuTypesInMemoryData = {}

class LibrarianDataCenter

    # LibrarianDataCenter::eventsToCliques(events)
    def self.eventsToCliques(events)
        cliques = {}
        events.each{|event|
            if cliques[event["uuid"]].nil? then
                cliques[event["uuid"]] = []
            end
            cliques[event["uuid"]] << event
        }
        cliques
    end

    # LibrarianDataCenter::cliquesToItems(cliques)
    def self.cliquesToItems(cliques)
        items = []
        cliques.values.each{|arr|
            items << arr.last
        }
        items
    end

    # LibrarianDataCenter::getTheGreatLibrarianCachePrefix()
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

    # LibrarianDataCenter::incomingEvent(event)
    # When a new object is created, we event log it and also internal dispatch it
    def self.incomingEvent(event)

        # --------------------------------------------------------------
        # Obsolete types

        if event["mikuType"] == "NxFlotille" then
            return
        end

        if event["mikuType"] == "TxFlt" then
            return
        end

        # --------------------------------------------------------------
        # Deletion

        if event["mikuType"] == "NxDeleted" then

            # Deletion (disk)
            object = Librarian::getObjectByUUIDOrNull(event["uuid"]) # calling this is the only way to get the mikuType
            if object then
                XCacheSets::destroy("#{LibrarianDataCenter::getTheGreatLibrarianCachePrefix()}:objects-by-mikuType:#{object["mikuType"]}", event["uuid"])
            end
            XCache::destroy("#{LibrarianDataCenter::getTheGreatLibrarianCachePrefix()}:object-by-uuid:#{event["uuid"]}")

            # Deletion (memory)
            mikuTypes = $MikuTypesInMemoryData.keys
            mikuTypes.each{|mikuType|
                $MikuTypesInMemoryData[mikuType].delete(event["uuid"])
            }

            return
        end

        # --------------------------------------------------------------
        # Generic mikuTypes handling

        # Generic get by uuid (disk)
        XCache::set("#{LibrarianDataCenter::getTheGreatLibrarianCachePrefix()}:object-by-uuid:#{event["uuid"]}", JSON.generate(event))
        
        # Generic get by mikuType (disk)
        XCacheSets::set("#{LibrarianDataCenter::getTheGreatLibrarianCachePrefix()}:objects-by-mikuType:#{event["mikuType"]}", event["uuid"], event)

        # Generic get by mikuType (memory)
        mikuType = event["mikuType"]
        if $MikuTypesInMemoryData[mikuType].nil? then
            $MikuTypesInMemoryData[mikuType] = {}
        end
        $MikuTypesInMemoryData[mikuType][event["uuid"]] = event

        # --------------------------------------------------------------
        # Types with specific data centers

        if event["mikuType"] == "NxBankOp" then
            $DoNotShowUntilDataCenter.incoming(event)
            return
        end

        if event["mikuType"] == "NxDNSU" then
            $DoNotShowUntilDataCenter.incoming(event)
            return
        end

        # --------------------------------------------------------------

        if event["mikuType"] == "Ax1Text" then
            return
        end

        if event["mikuType"] == "NxAnniversary" then
            return
        end

        if event["mikuType"] == "NxArrow" then
            return
        end

        if event["mikuType"] == "NxCollection" then
            return
        end

        if event["mikuType"] == "NxDataNode" then
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

    # LibrarianDataCenter::rebuildDatasetsFromScratchUsingEventLog()
    def self.rebuildDatasetsFromScratchUsingEventLog()
        puts "(reset librarian prefix)"
        XCache::set("TheGreatLibrarianCachePrefix-08b7-4327-a226-b9d29a876888", SecureRandom.hex)
        
        puts "(load events)"
        events  = EventLog::getLogEvents()

        puts "(events to cliques)"
        cliques = LibrarianDataCenter::eventsToCliques(events)

        puts "(cliques to items)"
        items   = LibrarianDataCenter::cliquesToItems(cliques)

        puts "(processing items)"

        $MikuTypesInMemoryData = {}

        $DoNotShowUntilDataCenter.reset()
        $BankDataCenter.reset()

        items.each{|item|
            puts JSON.pretty_generate(item)
            LibrarianDataCenter::incomingEvent(item)
        }
    end
end

class Librarian

    # ---------------------------------------------------
    # Objects Reading

    # Librarian::getObjectsByMikuType(mikuType)
    def self.getObjectsByMikuType(mikuType)
        if $MikuTypesInMemoryData[mikuType] then
            return $MikuTypesInMemoryData[mikuType].values.map{|item| item.clone }
        end

        $MikuTypesInMemoryData[mikuType] = {}

        puts "Librarian::getObjectsByMikuType(#{mikuType})"
        items = XCacheSets::values("#{LibrarianDataCenter::getTheGreatLibrarianCachePrefix()}:objects-by-mikuType:#{mikuType}")
        items.each{|item| $MikuTypesInMemoryData[mikuType][item["uuid"]] = item }
        
        $MikuTypesInMemoryData[mikuType].values.map{|item| item.clone }
    end

    # Librarian::getObjectByUUIDOrNull(uuid)
    def self.getObjectByUUIDOrNull(uuid)
        object = XCache::getOrNull("#{LibrarianDataCenter::getTheGreatLibrarianCachePrefix()}:object-by-uuid:#{uuid}")
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
        LibrarianDataCenter::incomingEvent(object)
    end

    # Librarian::destroy(uuid)
    def self.destroy(uuid)
        item = {
            "uuid"     => uuid,
            "mikuType" => "NxDeleted",
        }
        EventLog::commit(item)
        LibrarianDataCenter::incomingEvent(item)
    end
end
