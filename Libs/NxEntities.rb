
# encoding: UTF-8

class NxEntities

    # ----------------------------------------------------------------------
    # IO

    # NxEntities::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxEntity")
    end

    # NxEntities::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEntities::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxEntity")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        DxF1::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 291521ea-221b-4a81-9b6e-9ef0925d2ca5) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEntities::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("NxEntity")} #{item["description"]}"
    end
end
