
# encoding: UTF-8

class TopLevel

    # ----------------------------------------------------------------------
    # Objects Management

    # TopLevel::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "TopLevel"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "text"        => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "text"),
        }
    end

    # TopLevel::items()
    def self.items()
        Lookup1::mikuTypeToItems("TopLevel")
    end

    # TopLevel::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid", uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType", "TopLevel")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime", unixtime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime", datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "text", text)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = TopLevel::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: d794e690-2b62-46a1-822b-c8f60d7b4075) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TopLevel::getFirstLineOrNull(item)
    def self.getFirstLineOrNull(item)
        text = item["text"]
        return nil if text.nil?
        return nil if text == ""
        text.lines.first.strip
    end

    # TopLevel::toString(item)
    def self.toString(item)
        firstline = TopLevel::getFirstLineOrNull(item)
        return "(toplevel) (no text)" if firstline.nil?
        "(toplevel) #{firstline}"
    end

    # TopLevel::items()
    def self.items()
        Lookup1::mikuTypeToItems("TopLevel")
    end

    # TopLevel::section1()
    def self.section1()
        TopLevel::items()
    end

    # ----------------------------------------------------------------------
    # Operations

    # TopLevel::landing(uuid)
    def self.landing(uuid)
        loop {
            system("clear")
            item = Fx18s::getItemAliveOrNull(uuid)
            puts TopLevel::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                text = item["text"]
                text = CommonUtils::editTextSynchronously(text)
                Fx18Attributes::setJsonEncodeUpdate(uuid, "text", text)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{TopLevel::toString(item).green}' ? ") then
                    Fx18s::deleteObjectLogically(uuid)
                    break
                end
            end
        }
    end
end
