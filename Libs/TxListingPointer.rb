class TxListingPointer


    # TxListingPointer::interactivelyIssueNewTxListingPointer(item)
    def self.interactivelyIssueNewTxListingPointer(item)
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
        coordinates = TxListingCoordinates::interactivelyMakeNewTxListingCoordinates()
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxListingPointer",
            "resolver" => resolver,
            "listingCoordinates" => coordinates
        }
        filepath = "#{Config::pathToDataCenter()}/TxListingPointer/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        item
    end

    # TxListingPointer::items()
    def self.items()
        folderpath = "#{Config::pathToDataCenter()}/TxListingPointer"
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxListingPointer::stagedItemsOrdered()
    def self.stagedItemsOrdered()
        TxListingPointer::items()
            .select{|item| item["listingCoordinates"]["type"] == "staged" }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .map{|item| NxItemResolver1::getItemOrNull(item["resolver"]) }
            .compact
    end

    # TxListingPointer::ordinalPacketOrdered()
    def self.ordinalPacketOrdered()
        TxListingPointer::items()
            .select{|item| item["listingCoordinates"]["type"] == "ordinal" }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .map{|item|
                {
                    "item"    => NxItemResolver1::getItemOrNull(item["resolver"]),
                    "ordinal" => item["listingCoordinates"]["ordinal"]
                }
            }
            .select{|packet| packet["item"] }
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
end
