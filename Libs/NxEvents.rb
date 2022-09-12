
# encoding: UTF-8

class NxEvents

    # ----------------------------------------------------------------------
    # IO

    # NxEvents::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxEvent")
    end

    # NxEvents::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEvents::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        cx = Cx::interactivelyCreateNewCxForOwnerOrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = CommonUtils::interactiveDateTimeBuilder()
        DxF1::setAttribute2(uuid, "uuid",        uuid)
        DxF1::setAttribute2(uuid, "mikuType",    "NxEvent")
        DxF1::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        DxF1::setAttribute2(uuid, "datetime",    datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx112",       cx ? cx["uuid"] : nil)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: c4d9e89d-d4f2-4a44-8c66-311431977b4c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEvents::toString(item)
    def self.toString(item)
        "#{Stargate::formatTypeForToString("NxEvent")} #{item["description"]}"
    end
end
