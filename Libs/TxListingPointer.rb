class TxListingPointer

    # TxListingPointer::repositorypath()
    def self.repositorypath()
        "#{Config::pathToDataCenter()}/TxListingPointer"
    end

    # TxListingPointer::commit(item)
    def self.commit(item)
        filepath = "#{TxListingPointer::repositorypath()}/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TxListingPointer::interactivelyIssueNewTxListingPointerToItem(item)
    def self.interactivelyIssueNewTxListingPointerToItem(item)
        type = TxListingCoordinates::interactivelySelectTxListingCoordinatesType()
        if type == "staged" then
            return TxListingPointer::interactivelyIssueNewStaged(item)
        end
        if type == "ordinal" then
            return TxListingPointer::interactivelyIssueNewOrdinal(item)
        end
        raise "(error: 75148aa8-4689-45a3-8695-70422d36ca1b) unkonwn type: #{type}"
    end

    # TxListingPointer::interactivelyIssueNewStaged(item)
    def self.interactivelyIssueNewStaged(item)
        TxListingPointer::deleteAnyExistingPointerToItemUUID(item["uuid"])
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
        coordinates = {
            "mikuType" => "TxListingCoordinates",
            "type"     => "staged",
            "unixtime" => Time.new.to_f
        }
        pointer = {
            "uuid"               => SecureRandom.uuid,
            "mikuType"           => "TxListingPointer",
            "unixtime"           => Time.new.to_f,
            "datetime"           => Time.new.utc.iso8601,
            "resolver"           => resolver,
            "listingCoordinates" => coordinates
        }
        TxListingPointer::commit(pointer)
        pointer
    end

    # TxListingPointer::interactivelyIssueNewOrdinal(item)
    def self.interactivelyIssueNewOrdinal(item)
        TxListingPointer::deleteAnyExistingPointerToItemUUID(item["uuid"])
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        coordinates = {
            "mikuType" => "TxListingCoordinates",
            "type"     => "ordinal",
            "ordinal"  => ordinal
        }
        pointer = {
            "uuid"               => SecureRandom.uuid,
            "mikuType"           => "TxListingPointer",
            "unixtime"           => Time.new.to_f,
            "datetime"           => Time.new.utc.iso8601,
            "resolver"           => resolver,
            "listingCoordinates" => coordinates
        }
        TxListingPointer::commit(pointer)
        pointer
    end

    # TxListingPointer::items()
    def self.items()
        LucilleCore::locationsAtFolder(TxListingPointer::repositorypath())
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath| 
                item = JSON.parse(IO.read(filepath))
                if item["listingCoordinates"]["ordinal"] and item["datetime"][0, 10] != CommonUtils::today() then
                    FileUtils.rm(filepath)
                end
            }
        LucilleCore::locationsAtFolder(TxListingPointer::repositorypath())
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxListingPointer::stagedPackets()
    def self.stagedPackets()
        TxListingPointer::items()
            .select{|item| item["listingCoordinates"]["type"] == "staged" }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| 
                {
                    "pointer" => item,
                    "item"    => NxItemResolver1::getItemOrNull(item["resolver"]),
                }
            }
            .select{|packet| packet["item"] }
    end

    # TxListingPointer::ordinalPacketOrdered()
    def self.ordinalPacketOrdered()
        TxListingPointer::items()
            .select{|item| item["listingCoordinates"]["type"] == "ordinal" }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .map{|item|
                {
                    "pointer" => item,
                    "item"    => NxItemResolver1::getItemOrNull(item["resolver"]),
                    "ordinal" => item["listingCoordinates"]["ordinal"]
                }
            }
            .select{|packet| packet["item"] }
            .sort{|p1, p2| p1["ordinal"] <=> p2["ordinal"] }
    end

    # TxListingPointer::done(targetItemUUID)
    def self.done(targetItemUUID)
        folderpath = "#{Config::pathToDataCenter()}/TxListingPointer"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath| 
                item = JSON.parse(IO.read(filepath))
                if item["resolver"]["uuid"] == targetItemUUID then
                    FileUtils.rm(filepath)
                end
            }
    end

    # TxListingPointer::deleteAnyExistingPointerToItemUUID(uuid)
    def self.deleteAnyExistingPointerToItemUUID(uuid)
        folderpath = "#{Config::pathToDataCenter()}/TxListingPointer"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| 
                pointer = JSON.parse(IO.read(filepath)) 
                if pointer["resolver"]["uuid"] == uuid then
                    FileUtils.rm(filepath)
                end
            }
    end
end
