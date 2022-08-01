
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "Ax1Text"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "nhash"       => Fx18Attributes::getOrNull(objectuuid, "nhash"),
        }
    end

    # Ax1Text::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        nhash = ExData::putBlobInLocalDatablobsFolder(text)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::set_objectMaking(uuid, "uuid", uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType", "Ax1Text")
        Fx18Attributes::set_objectMaking(uuid, "unixtime", unixtime)
        Fx18Attributes::set_objectMaking(uuid, "datetime", datetime)
        Fx18Attributes::set_objectMaking(uuid, "nhash", nhash)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
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
        nhash = item["nhash"]
        text = ExData::getBlobOrNull(nhash)
        return nil if text.nil?
        return nil if text == ""
        text.lines.first
    end

    # Ax1Text::toString(item)
    def self.toString(item)
        firstline = Ax1Text::getFirstLineOrNull(item)
        return "(note) (no text)" if firstline.nil?
        "(note) #{firstline}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Ax1Text::landing(uuid)
    def self.landing(uuid)
        loop {
            system("clear")
            item = Fx18::itemOrNull(uuid)
            puts Ax1Text::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                nhash = Fx18Attributes::getOrNull(uuid, "nhash")
                text = ExData::getBlobOrNull(nhash)
                text = CommonUtils::editTextSynchronously(text)
                nhash = ExData::putBlobInLocalDatablobsFolder(text)
                Fx18Attributes::set_objectUpdate(uuid, "nhash", nhash)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{Ax1Text::toString(item).green}' ? ") then
                    Fx18::deleteObject(uuid)
                    break
                end
            end
        }
    end
end
