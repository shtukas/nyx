# encoding: UTF-8

class TheLibrarian

    # -----------------------------------------------------------
    # Utils

    # TheLibrarian::getObject(nhash)
    def self.getObject(nhash)
        JSON.parse(
            IO.read(
                DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash, true)
            )
        )
    end

    # TheLibrarian::setObject(object) # nhash
    def self.setObject(object)
        puts "TheLibrarian::setObject(#{JSON.pretty_generate(object)})"
        DataStore1::putDataByContent(JSON.generate(object))
    end

    # -----------------------------------------------------------
    # Getters

    # TheLibrarian::getPrimaryStructure()
    def self.getPrimaryStructure()
        filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/primary-structure.json"
        if File.exists?(filepath) then
            JSON.parse(IO.read(filepath))
        else
            {
                "banking" => nil
            }
        end
    end

    # TheLibrarian::getBankingObject()
    def self.getBankingObject()
        primary = TheLibrarian::getPrimaryStructure()
        if primary["banking"] then
            TheLibrarian::getObject(primary["banking"])
        else
            {
                "mikuType" => "PrimaryStructure.v1:Banking",
                "mapping"  => {}
            }
        end
    end

    # TheLibrarian::getBankingObjectArrayEventsForSet(setuuid)
    def self.getBankingObjectArrayEventsForSet(setuuid)
        banking = TheLibrarian::getBankingObject()
        if banking["mapping"][setuuid].nil? then
            return []
        end
        nhash = banking["mapping"][setuuid]
        TheLibrarian::getObject(nhash)
    end

    # TheLibrarian::getDoNotShowUntilObject()
    def self.getDoNotShowUntilObject()
        primary = TheLibrarian::getPrimaryStructure()
        if primary["doNotShowUntil"] then
            TheLibrarian::getObject(primary["doNotShowUntil"])
        else
            {
                "mikuType" => "PrimaryStructure.v1:DoNotShowUntil",
                "mapping"  => {}
            }
        end
    end

    # TheLibrarian::getNetworkEdges()
    def self.getNetworkEdges()
        primary = TheLibrarian::getPrimaryStructure()
        if primary["networkEdges"] then
            TheLibrarian::getObject(primary["networkEdges"])
        else
            {
                "mikuType" => "PrimaryStructure.v1:NetworkEdges",
                "edges"    => []
            }
        end
    end

    # -----------------------------------------------------------
    # Setters

    # TheLibrarian::setPrimaryStructure(object)
    def self.setPrimaryStructure(object)
        puts "TheLibrarian::setPrimaryStructure(#{JSON.pretty_generate(object)})"

        filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/primary-structure.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        
        folderpath1 = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/primary-structure"
        folderpath2 = LucilleCore::indexsubfolderpath(folderpath1, capacity = 100)
        filepath2 = "#{folderpath2}/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath2, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # TheLibrarian::setBankingObject(banking)
    def self.setBankingObject(banking)
        nhash = TheLibrarian::setObject(banking)
        primary = TheLibrarian::getPrimaryStructure()
        primary["banking"] = nhash
        TheLibrarian::setPrimaryStructure(primary)
    end

    # TheLibrarian::setBankingEventsArrayAtSet(setuuid, events)
    def self.setBankingEventsArrayAtSet(setuuid, events)
        banking = TheLibrarian::getBankingObject()
        banking["mapping"][setuuid] = TheLibrarian::setObject(events)
        TheLibrarian::setBankingObject(banking)
    end

    # TheLibrarian::setDoNotShowUntilObject(object)
    def self.setDoNotShowUntilObject(object)
        nhash = TheLibrarian::setObject(object)
        primary = TheLibrarian::getPrimaryStructure()
        primary["doNotShowUntil"] = nhash
        TheLibrarian::setPrimaryStructure(primary)
    end

    # TheLibrarian::setNetworkEdges(object)
    def self.setNetworkEdges(object)
        nhash = TheLibrarian::setObject(object)
        primary = TheLibrarian::getPrimaryStructure()
        primary["networkEdges"] = nhash
        TheLibrarian::setPrimaryStructure(primary)
    end

    # -----------------------------------------------------------
    # Events

    # TheLibrarian::processEvent(event)
    def self.processEvent(event)

        if event["mikuType"] == "TxBankEvent" then
            #[Event] TxBankEvent
            #{
            #    "mikuType"  => "TxBankEvent",
            #    "eventuuid" => eventuuid,
            #    "eventTime" => Float,
            #    "setuuid"   => setuuid,
            #    "unixtime"  => unixtime,
            #    "date"      => date,
            #    "weight"    => weight
            #}
            FileSystemCheck::fsckTxBankEvent(event)
            banking = TheLibrarian::getBankingObject()
            setuuid = event["setuuid"]
            eventuuid = event["eventuuid"]
            events = TheLibrarian::getBankingObjectArrayEventsForSet(setuuid)
            return if events.any?{|e| e["eventuuid"] == eventuuid } # We already have it
            events << event
            events = events.sort{|e1, e2| e1["eventTime"] <=> e2["eventTime"] }
            TheLibrarian::setBankingEventsArrayAtSet(setuuid, events)
        end

        if event["mikuType"] == "NxDoNotShowUntil" then
            #{
            #    "mikuType"       => "NxDoNotShowUntil",
            #    "targetuuid"     => uuid,
            #    "targetunixtime" => unixtime
            #}
            FileSystemCheck::fsckNxDoNotShowUntil(event)
            dnsu = TheLibrarian::getDoNotShowUntilObject()
            targetuuid = event["targetuuid"]
            targetunixtime = event["targetunixtime"]
            dnsu["mapping"][targetuuid] = targetunixtime
            TheLibrarian::setDoNotShowUntilObject(dnsu)
        end

        if event["mikuType"] == "NxGraphEdge1" then
            #NxGraphEdge1 {
            #    "mikuType" : "NxGraphEdge1"
            #    "unixtime" : Float
            #    "uuid1"    : String
            #    "uuid2"    : String
            #    "type"     : "bidirectional" | "arrow" | "none"
            #}
            networkEdges = TheLibrarian::getNetworkEdges()
            # The operation there is to remove any item that link those two nodes and to add this one
            edges = networkEdges["edges"]

            areEquivalents = lambda {|itemA, itemB|
                return true if (itemA["uuid1"] == itemB["uuid1"] and itemA["uuid2"] == itemB["uuid2"])
                return true if (itemA["uuid1"] == itemB["uuid2"] and itemA["uuid2"] == itemB["uuid1"])
                false
            }

            itemIsOlderThanEvent = lambda {|item, event|
                # meaning that the item unixtime is lower than the event unixtime
                item["unixtime"] < event["unixtime"]
            }

            itemIsNewerThanEvent = lambda {|item, event|
                # meaning that the item unixtime is greater or equal than the event unixtime
                item["unixtime"] >= event["unixtime"]
            }

            # We stop processing the event if there is an equivalent item that is newer than the event
            return if edges.any?{|item| areEquivalents.call(item, event) and itemIsNewerThanEvent.call(item, event) }

            # Starting by dropping items equivalent to the event
            edges = edges.reject{|item| areEquivalents.call(item, event) }

            # And now we add the event to the list
            edges << event

            networkEdges["edges"] = edges

            TheLibrarian::setNetworkEdges(networkEdges)
        end

    end

end
