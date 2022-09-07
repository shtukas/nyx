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
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        ax39 = nil
        if shouldPromptForTimeCommitment and LucilleCore::askQuestionAnswerAsBoolean("Attach a Ax39 (time commitment) ? ", false) then
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
        end
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxTask")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        DxF1::setAttribute2(uuid, "ax39",        ax39)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        ownee = CxUrl::issueNewForOwner(uuid, url)
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxTask")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       ownee["uuid"])
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
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
        cx = CxAionPoint::issueNewForOwnerOrNull(uuid, location)
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxTask")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil) # possibly null, in principle, although not in the case of a location
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7938316c-cb54-4d60-a480-f161f19718ef) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueDescriptionOnly(description)
    def self.issueDescriptionOnly(description)
        uuid  = SecureRandom.uuid
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxTask")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
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
            ax39str = item["ax39"] ? " #{Ax39::toString(item)}" : ""
            "(task)#{Cx::uuidToString(item["nx112"])} #{item["description"]}#{ax39str}"
        }
        builder.call()
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::cacheduuidsForSection2()
    def self.cacheduuidsForSection2()
        key = "d0c5d86c-a815-4250-a746-9b93ecd4f443"
        itemuuids = XCacheValuesWithExpiry::getOrNull(key)
        return itemuuids if itemuuids

        itemuuids = TheIndex::mikuTypeToObjectuuids("NxTask").reduce([]){|selected, itemuuid|
            echoIfValid = lambda{|itemuuid|
                item = TheIndex::getItemOrNull(itemuuid)
                return nil if nil? # this should never happen considering how `itemuuids` was made.
                return nil if item["ax39"]
                return nil if OwnerMapping::elementuuidToOwnersuuids(item["uuid"]).size > 0
                itemuuid
            }
            if selected.size >= 32 then
                selected
            else
                ix = echoIfValid.call(itemuuid)
                if ix then
                    selected + [ix]
                else
                    selected
                end
            end
        }

        XCacheValuesWithExpiry::set(key, itemuuids, 86400)

        itemuuids
    end

    # NxTasks::listingItems()
    def self.listingItems()
        NxTasks::cacheduuidsForSection2()
        .map{|itemuuid| TheIndex::getItemOrNull(itemuuid) }
        .compact
    end

    # NxTasks::topUnixtime()
    def self.topUnixtime()
        ([Time.new.to_f] + NxTasks::items().map{|item| item["unixtime"] }).min - 1
    end
end
