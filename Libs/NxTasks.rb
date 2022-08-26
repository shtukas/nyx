# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxTask")
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull(shouldPromptForTimeCommitment)
    def self.interactivelyCreateNewOrNull(shouldPromptForTimeCommitment)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        ax39 = nil
        if shouldPromptForTimeCommitment and LucilleCore::askQuestionAnswerAsBoolean("Attach a Ax39 (time commitment) ? ", false) then
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
        end
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxTask")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111) # possibly null
        DxF1::setJsonEncoded(uuid, "ax39",        ax39) # possibly null
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxTask")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: f78008bf-12d4-4483-b4bb-96e3472d46a2) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        if !File.exists?(location) then
            raise "(error: 52b8592f-a61a-45ef-a886-ed2ab4cec5ed)"
        end
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToNx111DxPureAionPoint(uuid, location)
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxTask")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111) # possibly null, in principle, although not in the case of a location
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7938316c-cb54-4d60-a480-f161f19718ef) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueDescriptionOnlyNoNx111(description)
    def self.issueDescriptionOnlyNoNx111(description)
        uuid  = SecureRandom.uuid
        nx111 = nil
        DxF1::setJsonEncoded(uuid, "uuid",        uuid)
        DxF1::setJsonEncoded(uuid, "mikuType",    "NxTask")
        DxF1::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        DxF1::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        DxF1::broadcastObjectFile(uuid)
        item = DxF1::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 5ea6abff-1007-4bd5-ab61-bde26c621a8b) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : " (line)"
            ax39str = item["ax39"] ? " #{Ax39::toString(item)}" : ""
            "(task)#{nx111String} #{item["description"]}#{ax39str}"
        }
        builder.call()
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::topItemsForSection2()
    def self.topItemsForSection2()
        key = "Top-Tasks-For-Section2-7be0c69eaed3"
        items = XCacheValuesWithExpiry::getOrNull(key)
        return items if items

        items = NxTasks::items()
                .select{|item| item["ax39"].nil? }
                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                .select{|item| OwnerMapping::elementuuidToOwnersuuids(item["uuid"]).empty? }
                .first(50)

        XCacheValuesWithExpiry::set(key, items, 86400)

        items
    end

    # NxTasks::listingItems()
    def self.listingItems()
        NxTasks::topItemsForSection2()
            .select{|item| item["ax39"].nil? }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .first(6)
    end

    # NxTasks::topUnixtime()
    def self.topUnixtime()
        ([Time.new.to_f] + NxTasks::items().map{|item| item["unixtime"] }).min - 1
    end
end
