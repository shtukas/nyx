
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "Ax1Text"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "nhash"       => Fx18Attributes::getOrNull(objectuuid, "nhash"),
        }
    end

    # Ax1Text::interactivelyIssueNew()
    def self.interactivelyIssueNew()
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        text = CommonUtils::editTextSynchronously("")
        nhash = Fx18LocalObjectsDataWithInfinityHelp::putBlob3(uuid, text)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18Attributes::setAttribute2(uuid, "uuid", uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType", "Ax1Text")
        Fx18Attributes::setAttribute2(uuid, "unixtime", unixtime)
        Fx18Attributes::setAttribute2(uuid, "datetime", datetime)
        Fx18Attributes::setAttribute2(uuid, "nhash", nhash)

        FileSystemCheck::fsckLocalObjectuuid(uuid)

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
        text = Fx18LocalObjectsDataWithInfinityHelp::getBlobOrNull(item["uuid"], nhash)
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
            item = Fx18Utils::objectuuidToItemOrNull(uuid)
            puts Ax1Text::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                nhash = Fx18Attributes::getOrNull(uuid, "nhash")
                text = Fx18LocalObjectsDataWithInfinityHelp::getBlobOrNull(uuid, nhash)
                text = CommonUtils::editTextSynchronously(text)
                nhash = Fx18LocalObjectsDataWithInfinityHelp::putBlob3(uuid, text)
                Fx18Attributes::setAttribute2(uuid, "nhash", nhash)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{Ax1Text::toString(item).green}' ? ") then
                    Fx18Utils::destroyFx18EmitEvents(uuid)
                    break
                end
            end
        }
    end
end
