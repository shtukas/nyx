
# encoding: UTF-8

class DxLine

    # DxLine::items()
    def self.items()
        TheIndex::mikuTypeToItems("DxLine")
    end

    # DxLine::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        line = LucilleCore::askQuestionAnswerAsString("line (empty to abort): ")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        DxF1::setJsonEncoded(uuid, "uuid", uuid)
        DxF1::setJsonEncoded(uuid, "mikuType", "DxLine")
        DxF1::setJsonEncoded(uuid, "unixtime", unixtime)
        DxF1::setJsonEncoded(uuid, "datetime", datetime)
        DxF1::setJsonEncoded(uuid, "line", line)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid)
        item = TheIndex::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # DxLine::getFirstLineOrNull(item)
    def self.getFirstLineOrNull(item)
        text = item["text"]
        return nil if text.nil?
        return nil if text == ""
        text.lines.first.strip
    end

    # DxLine::toString(item)
    def self.toString(item)
        firstline = DxLine::getFirstLineOrNull(item)
        return "(note) (no text)" if firstline.nil?
        "(note) #{firstline}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # DxLine::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            uuid = item["uuid"]
            puts DxLine::toString(item)
            operations = [
                "access",
                "edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access" then
                CommonUtils::accessText(item["text"])
            end
            if operation == "edit" then
                text = CommonUtils::editTextSynchronously(item["text"])
                DxF1::setJsonEncoded(uuid, "text", text)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{DxLine::toString(item).green}' ? ") then
                    DxF1::deleteObjectLogically(uuid)
                    break
                end
            end
        }
    end
end
