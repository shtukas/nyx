class TxListingPointer

    # TxListingPointer::commit(item)
    def self.commit(item)
        filepath = "#{Config::pathToDataCenter()}/TxListingPointer/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # TxListingPointer::interactivelyIssueNewTxListingPointerToItem(item)
    def self.interactivelyIssueNewTxListingPointerToItem(item)
        TxListingPointer::deleteAnyExistingPointerToItemUUID(item["uuid"])
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
        coordinates = TxListingCoordinates::interactivelyMakeNewTxListingCoordinates()
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxListingPointer",
            "resolver" => resolver,
            "listingCoordinates" => coordinates
        }
        TxListingPointer::commit(item)
        BankLoan1::interactiveLoanOffer()
        item
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
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxListingPointer",
            "resolver" => resolver,
            "listingCoordinates" => coordinates
        }
        filepath = "#{Config::pathToDataCenter()}/TxListingPointer/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        BankLoan1::interactiveLoanOffer()
        item
    end

    # TxListingPointer::interactivelyIssueNewStaging(item)
    def self.interactivelyIssueNewStaging(item)
        TxListingPointer::deleteAnyExistingPointerToItemUUID(item["uuid"])
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
        coordinates = {
            "mikuType" => "TxListingCoordinates",
            "type"     => "staged",
            "unixtime" => Time.new.to_f
        }
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxListingPointer",
            "resolver" => resolver,
            "listingCoordinates" => coordinates
        }
        filepath = "#{Config::pathToDataCenter()}/TxListingPointer/#{item["uuid"]}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(item)) }
        BankLoan1::interactiveLoanOffer()
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
