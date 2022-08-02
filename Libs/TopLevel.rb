
# encoding: UTF-8

class TopLevel

    # ----------------------------------------------------------------------
    # Objects Management

    # TopLevel::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "TopLevel"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "nhash"       => Fx18Attributes::getOrNull(objectuuid, "nhash"),
        }
    end

    # TopLevel::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        text = CommonUtils::editTextSynchronously("")
        nhash = ExData::putBlobInLocalDatablobsFolder(text)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::set_objectMaking(uuid, "uuid", uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType", "TopLevel")
        Fx18Attributes::set_objectMaking(uuid, "unixtime", unixtime)
        Fx18Attributes::set_objectMaking(uuid, "datetime", datetime)
        Fx18Attributes::set_objectMaking(uuid, "nhash", nhash)
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
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
        nhash = item["nhash"]
        text = ExData::getBlobOrNull(nhash)
        return nil if text.nil?
        return nil if text == ""
        text.lines.first
    end

    # TopLevel::toString(item)
    def self.toString(item)
        firstline = TopLevel::getFirstLineOrNull(item)
        return "(toplevel) (no text)" if firstline.nil?
        "(toplevel) #{firstline}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # TopLevel::landing(uuid)
    def self.landing(uuid)
        loop {
            system("clear")
            item = Fx18::itemOrNull(uuid)
            puts TopLevel::toString(item)
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
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{TopLevel::toString(item).green}' ? ") then
                    Fx18::deleteObject(uuid)
                    break
                end
            end
        }
    end
end
