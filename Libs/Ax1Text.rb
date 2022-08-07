
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType") != "Ax1Text"
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "datetime"),
            "text"        => Fx18Attributes::getJsonDecodeOrNull(objectuuid, "text"),
        }
        # Sometimes, when we do lookup1 Lookup1::reconstructEntry during a commline update
        # and Fx18s::getItemAliveOrNull(objectuuid) returns something
        # that thing may not have text considering that the events come in order of "uuid", "mikuType", "unixtime", "datetime", "text"
        return nil if item["text"].nil?
        item
    end

    # Ax1Text::items()
    def self.items()
        Lookup1::mikuTypeToItems("Ax1Text")
    end

    # Ax1Text::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "uuid", uuid)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "mikuType", "Ax1Text")
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "unixtime", unixtime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "datetime", datetime)
        Fx18Attributes::setJsonEncodeObjectMaking(uuid, "text", text)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        Fx18s::broadcastObjectEvents(uuid)
        item = Ax1Text::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 0f512f44-6d46-4f15-9015-ca4c7bfe6d9c) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Ax1Text::getFirstLineOrNull(item)
    def self.getFirstLineOrNull(item)
        text = item["text"]
        return nil if text.nil?
        return nil if text == ""
        text.lines.first.strip
    end

    # Ax1Text::toString(item)
    def self.toString(item)
        firstline = Ax1Text::getFirstLineOrNull(item)
        return "(note) (no text)" if firstline.nil?
        "(note) #{firstline}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Ax1Text::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            uuid = item["uuid"]
            puts Ax1Text::toString(item)
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
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{Ax1Text::toString(item).green}' ? ") then
                    Fx18s::deleteObject(uuid)
                    break
                end
            end
        }
    end
end
