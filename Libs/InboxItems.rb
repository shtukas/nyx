# encoding: UTF-8

class InboxItems

    # InboxItems::items()
    def self.items()
        TheIndex::mikuTypeToItems("InboxItem")
    end

    # InboxItems::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # InboxItems::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "InboxItem")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 544580ef-38aa-4c02-8ecd-1667c8adc275) How did that happen ? 🤨"
        end
        item
    end

    # InboxItems::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        if !File.exists?(location) then
            raise "(error: f54482c2-096f-46b0-acf4-d3ba1893704f)"
        end
        description = File.basename(location)
        uuid = SecureRandom.uuid
        cx = CxAionPoint::issueNewForOwnerOrNull(uuid, location)
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "InboxItem")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil) # possibly null, in principle, although not in the case of a location
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 469576fc-9c69-41c4-9935-16df02731292) How did that happen ? 🤨"
        end
        item
    end

    # InboxItems::issueDescriptionOnly(description)
    def self.issueDescriptionOnly(description)
        uuid  = SecureRandom.uuid
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "InboxItem")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: a1ed4cc6-ef77-4b83-9ccf-936a3ab6a960) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # InboxItems::toString(item)
    def self.toString(item)
        "(inbox)#{Cx::uuidToString(item["nx112"])} #{item["description"]}"
    end

    # InboxItems::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(inbox) #{item["description"]}"
    end

    # InboxItems::listingItems()
    def self.listingItems()
        InboxItems::items()
            .select{|item| item["isAlive"].nil? or item["isAlive"] }
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end
end
