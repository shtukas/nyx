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

    # TxListingPointer::items()
    def self.items()
        LucilleCore::locationsAtFolder(TxListingPointer::repositorypath())
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # TxListingPointer::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        LucilleCore::locationsAtFolder(TxListingPointer::repositorypath())
            .select{|filepath| filepath[-5, 5] == ".json" }
            .each{|filepath| 
                item = JSON.parse(IO.read(filepath))
                return if item["uuid"] == uuid
            }
    end

    # TxListingPointer::done(pointer)
    def self.done(pointer)
        if pointer["resolver"]["mikuType"] == "NxItemResolver1" then
            resolver = pointer["resolver"]
            item = NxItemResolver1::getItemOrNull(resolver)
            if item then
                PolyActions::done(item, true)
            end
        end

        filepath = "#{TxListingPointer::repositorypath()}/#{pointer["uuid"]}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # -------------------------------------------------

    # TxListingPointer::issueNewWithItem(item)
    def self.issueNewWithItem(item)
        resolver = NxItemResolver1::make(item["uuid"], item["mikuType"])
        pointer = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxListingPointer",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "resolver" => resolver,
        }
        TxListingPointer::commit(pointer)
        pointer
    end

    # TxListingPointer::issueNewWithAnnounce(announce)
    def self.issueNewWithAnnounce(announce)
        resolver = NxItemResolver2::make(announce)
        pointer = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "TxListingPointer",
            "unixtime" => Time.new.to_f,
            "datetime" => Time.new.utc.iso8601,
            "resolver" => resolver,
        }
        TxListingPointer::commit(pointer)
        pointer
    end

    # TxListingPointer::toString(pointer)
    def self.toString(pointer)

        resolver = pointer["resolver"]

        if resolver["mikuType"] == "NxItemResolver1" then
            item     = NxItemResolver1::getItemOrNull(resolver)
            itemStr  = item ? PolyFunctions::toStringForListing(item) : "(item not found for resolver: #{resolver})"
            return "(pointer) #{itemStr}"
        end

        if resolver["mikuType"] == "NxItemResolver2" then
            return "(line) #{resolver["announce"]}"
        end
    end

    def self.pointerToItemUUIDOrNull(pointer)
        if pointer["resolver"]["mikuType"] == "NxItemResolver1" then
            item = NxItemResolver1::getItemOrNull(pointer["resolver"])
            if item then
                item["uuid"]
            end
        end
        nil
    end
end
