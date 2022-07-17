
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "Ax1Text"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "nhash"       => Fx18File::getAttributeOrNull(objectuuid, "nhash"),
        }
    end

    # Ax1Text::interactivelyIssueNewOrNullForOwner() # uuid
    def self.interactivelyIssueNewOrNullForOwner()
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        text = CommonUtils::editTextSynchronously("")
        nhash = Fx18File::putBlob3(uuid, text)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18File::setAttribute2(uuid, "uuid", uuid)
        Fx18File::setAttribute2(uuid, "mikuType", "Ax1Text")
        Fx18File::setAttribute2(uuid, "unixtime", unixtime)
        Fx18File::setAttribute2(uuid, "datetime", datetime)
        Fx18File::setAttribute2(uuid, "nhash", nhash)
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # Ax1Text::toString(uuid)
    def self.toString(uuid)
        nhash = Fx18File::getAttributeOrNull(uuid, "nhash")
        text = Fx18File::getBlobOrNull(uuid, nhash) # This should not be null
        description = (text != "") ? text.lines.first : "(empty text)"
        "(note) #{description}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Ax1Text::landing(uuid)
    def self.landing(uuid)
        loop {
            system("clear")
            puts Ax1Text::toString(uuid)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                nhash = Fx18File::getAttributeOrNull(uuid, "nhash")
                text = Fx18File::getBlobOrNull(uuid, nhash)
                text = CommonUtils::editTextSynchronously(text)
                nhash = Fx18File::putBlob3(uuid, text)
                Fx18File::setAttribute2(uuid, "nhash", nhash)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{Ax1Text::toString(uuid).green}' ? ") then
                    Fx18File::destroy(uuid)
                    break
                end
            end
        }
    end
end
