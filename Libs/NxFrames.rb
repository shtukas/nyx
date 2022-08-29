# encoding: UTF-8

class NxFrames

    # NxFrames::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxFrame")
    end

    # NxFrames::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxFrames::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxFrame")
        DxF1::setAttribute2(uuid, "unixtime",    unixtime)
        DxF1::setAttribute2(uuid, "datetime",    datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: b63ae301-b0a1-47da-a445-8c53a457d0fe) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # NxFrames::toString(item)
    def self.toString(item)
        "(frame) #{item["description"]}#{Cx::uuidToString(item["nx112"])}"
    end

    # NxFrames::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(frame) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxFrames::dive()
    def self.dive()
        loop {
            system("clear")
            items = NxFrames::items()
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"]}
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("frame", items, lambda{|item| LxFunction::function("toString", item) })
            return if item.nil?
            Landing::landing_old(item, false)
        }
    end
end
