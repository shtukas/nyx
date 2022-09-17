
# encoding: UTF-8

class NyxNode

    # NyxNode::items()
    def self.items()
        TheIndex::mikuTypeToItems("NyxNode")
    end

    # NyxNode::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx113nhash = CommonUtils::interactivelySelectDesktopLocationOrNull()

        DxF1::setAttribute2(uuid, "uuid", uuid)
        DxF1::setAttribute2(uuid, "mikuType", "NyxNode")
        DxF1::setAttribute2(uuid, "unixtime", unixtime)
        DxF1::setAttribute2(uuid, "datetime", datetime)
        DxF1::setAttribute2(uuid, "description", description)
        DxF1::setAttribute2(uuid, "nx113", nx113nhash)

        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 6035de89-5fbc-4882-a6f9-f1f703e8b106) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NyxNode::toString(item)
    def self.toString(item)
        prefix = Nx113Access::toStringOrNull(nhash)
        prefix = prefix ? "#{prefix} " : prefix
        "#{prefix} #{item["description"]}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # NyxNode::access(item)
    def self.access(item)
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        else
            puts item["description"]
            LucilleCore::pressEnterToContinue()
        end
    end

    # NyxNode::edit(item) # item
    def self.edit(item)
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end
end
