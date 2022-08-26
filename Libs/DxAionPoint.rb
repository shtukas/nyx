
# encoding: UTF-8

class DxAionPoint

    # DxAionPoint::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxAionPoint")
    end

    # DxAionPoint::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description.nil?

        location = CommonUtils::interactivelySelectDesktopLocationOrNull()
        return nil if location.nil?

        operator = DxF1Elizabeth.new(uuid)

        rootnhash = AionCore::commitLocationReturnHash(operator, location)

        DxF1::setJsonEncoded(uuid, "uuid", uuid)
        DxF1::setJsonEncoded(uuid, "mikuType", "DxAionPoint")
        DxF1::setJsonEncoded(uuid, "unixtime", unixtime)
        DxF1::setJsonEncoded(uuid, "datetime", datetime)
        DxF1::setJsonEncoded(uuid, "description", description)
        DxF1::setJsonEncoded(uuid, "rootnhash", rootnhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 4cb89267-dcd5-44ca-8f06-530a8089cb3c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxAionPoint::toString(item)
    def self.toString(item)
        "(DxAionPoint) #{item["url"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxAionPoint::access(item)
    def self.access(item)
        puts "DxAionPoint: #{item["url"]}"
        LucilleCore::pressEnterToContinue()
    end
end
