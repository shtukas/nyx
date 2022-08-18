# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        Fx256WithCache::mikuTypeToItems("NxTask")
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Fx256::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        ax39 = nil
        if LucilleCore::askQuestionAnswerAsBoolean("Attach a Ax39 (time commitment) ? ", false) then
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
        end
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        Fx18Attributes::setJsonEncoded(uuid, "nx111",       nx111) # possibly null
        Fx18Attributes::setJsonEncoded(uuid, "ax39",        ax39) # possibly null
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
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
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        Fx18Attributes::setJsonEncoded(uuid, "nx111",       nx111)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
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
        nx111 = Nx111::locationToAionPointNx111(uuid, location)
        Fx18Attributes::setJsonEncoded(uuid, "uuid",        uuid)
        Fx18Attributes::setJsonEncoded(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setJsonEncoded(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setJsonEncoded(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setJsonEncoded(uuid, "description", description)
        Fx18Attributes::setJsonEncoded(uuid, "nx111",       nx111) # possibly null, in principle, although not in the case of a location
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        Fx256::broadcastObjectEvents(uuid)
        item = Fx256::getProtoItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7938316c-cb54-4d60-a480-f161f19718ef) How did that happen ? 🤨"
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

    # NxTasks::section2()
    def self.section2()
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
