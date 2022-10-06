# encoding: UTF-8

$TheLibrarianInMemoryObjectCache = {}

class TheLibrarian

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
            DataStore3CAObjects::getObject(primary["banking"])
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
        DataStore3CAObjects::getObject(nhash)
    end

    # TheLibrarian::getDoNotShowUntilObject()
    def self.getDoNotShowUntilObject()
        primary = TheLibrarian::getPrimaryStructure()
        if primary["doNotShowUntil"] then
            DataStore3CAObjects::getObject(primary["doNotShowUntil"])
        else
            {
                "mikuType" => "PrimaryStructure.v1:DoNotShowUntil",
                "mapping"  => {}
            }
        end
    end

    # TheLibrarian::getItems()
    def self.getItems()
        primary = TheLibrarian::getPrimaryStructure()
        if primary["items"] then
            DataStore3CAObjects::getObject(primary["items"])
        else
            {
                "mikuType" => "PrimaryStructure.v1:Items",
                "mapping"  => {}
            }
        end
    end

    # -----------------------------------------------------------
    # Setters

    # TheLibrarian::setPrimaryStructure(object)
    def self.setPrimaryStructure(object)
        #puts "TheLibrarian::setPrimaryStructure(#{JSON.pretty_generate(object)})"

        FileSystemCheck::fsckPrimaryStructureV1(object, false, FileSystemCheck::getExistingRunHash(), false)

        filepath = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/primary-structure.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        
        folderpath1 = "#{ENV['HOME']}/Galaxy/DataBank/Stargate/primary-structure"
        folderpath2 = LucilleCore::indexsubfolderpath(folderpath1, capacity = 100)
        filepath2 = "#{folderpath2}/#{CommonUtils::timeStringL22()}.json"
        File.open(filepath2, "w"){|f| f.puts(JSON.pretty_generate(object)) }
    end

    # TheLibrarian::setBankingObject(object)
    def self.setBankingObject(object)
        FileSystemCheck::fsckPrimaryStructureV1Banking(object, FileSystemCheck::getExistingRunHash(), false)
        nhash = DataStore3CAObjects::setObject(object)
        primary = TheLibrarian::getPrimaryStructure()
        primary["banking"] = nhash
        TheLibrarian::setPrimaryStructure(primary)
    end

    # TheLibrarian::setBankingEventsArrayAtSet(setuuid, events)
    def self.setBankingEventsArrayAtSet(setuuid, events)
        banking = TheLibrarian::getBankingObject()
        banking["mapping"][setuuid] = DataStore3CAObjects::setObject(events)
        TheLibrarian::setBankingObject(banking)
    end

    # TheLibrarian::setDoNotShowUntilObject(object)
    def self.setDoNotShowUntilObject(object)
        FileSystemCheck::fsckPrimaryStructureV1DoNotShowUntil(object, FileSystemCheck::getExistingRunHash(), false)
        nhash = DataStore3CAObjects::setObject(object)
        primary = TheLibrarian::getPrimaryStructure()
        primary["doNotShowUntil"] = nhash
        TheLibrarian::setPrimaryStructure(primary)
    end

    # TheLibrarian::setItems(object)
    def self.setItems(object)
        FileSystemCheck::fsckPrimaryStructureV1Items(object, false, FileSystemCheck::getExistingRunHash(), false)
        nhash = DataStore3CAObjects::setObject(object)
        primary = TheLibrarian::getPrimaryStructure()
        primary["items"] = nhash
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
            FileSystemCheck::fsckTxBankEvent(event, SecureRandom.hex, false)
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
            FileSystemCheck::fsckNxDoNotShowUntil(event, SecureRandom.hex, false)
            dnsu = TheLibrarian::getDoNotShowUntilObject()
            targetuuid = event["targetuuid"]
            targetunixtime = event["targetunixtime"]
            dnsu["mapping"][targetuuid] = targetunixtime
            TheLibrarian::setDoNotShowUntilObject(dnsu)
        end

        if event["mikuType"] == "AttributeUpdate.v2" then
            #{
            #    "mikuType"   => "AttributeUpdate.v2"
            #    "objectuuid" => objectuuid
            #    "eventuuid"  => String
            #    "eventTime"  => Float
            #    "attname"    => string
            #    "attvalue"   => value
            #}
            FileSystemCheck::fsckAttributeUpdateV2(event, SecureRandom.hex, false)
            items = TheLibrarian::getItems()

            eventsToItemOrNull = lambda{|events|
                item = {}
                events.each{|event|
                    item[event["attname"]] = event["attvalue"]
                }
                if item["uuid"].nil? or item["mikuType"].nil? then
                    item = nil
                end
                item
            }

            mapping = items["mapping"]
            if mapping[event["objectuuid"]] then
                 # We have a NxItemSphere1
                 nxItemSphere1 = DataStore3CAObjects::getObject(mapping[event["objectuuid"]])
                 nxItemSphere1["events"] = nxItemSphere1["events"].reject{|e| e["eventuuid"] == event["eventuuid"] }
                 nxItemSphere1["events"] << event
                 nxItemSphere1["events"] = nxItemSphere1["events"].sort{|e1, e2| e1["eventTime"] <=> e2["eventTime"] }
                 
                 item = eventsToItemOrNull.call(nxItemSphere1["events"])
                 nxItemSphere1["item"] = item
                 if item then
                    ItemsInMemoryCache::incomingItem(item)
                 end
            else
                 # We need to create the NxItemSphere1
                 nxItemSphere1 = {
                    "mikuType" => "NxItemSphere1",
                    "item"     => nil,
                    "events"   => [event]
                 }
            end
            nhash = DataStore3CAObjects::setObject(nxItemSphere1)
            mapping[event["objectuuid"]] = nhash
            items["mapping"] = mapping
            TheLibrarian::setItems(items)
        end
    end

end
