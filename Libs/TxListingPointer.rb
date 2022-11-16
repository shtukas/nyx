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

    # TxListingPointer::interactivelyIssueNewStaged(item)
    def self.interactivelyIssueNewStaged(item)
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
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
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxListingPointer::packets()
    def self.packets()
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

    # TxListingPointer::toString(pointer)
    def self.toString(pointer)
        resolver = pointer["resolver"]
        item     = NxItemResolver1::getItemOrNull(resolver)
        itemStr  = item ? PolyFunctions::toStringForListing(item) : "(item not found for resolver: #{resolver})"
        "(pointer) #{itemStr}"
    end

    # TxListingPointer::destroy(uuid)
    def self.destroy(uuid)
        filepath = "#{TxListingPointer::repositorypath()}/#{item["uuid"]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
