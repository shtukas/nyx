
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::interactivelyIssueNewOrNullForOwner() # uuid
    def self.interactivelyIssueNewOrNullForOwner()
        uuid = SecureRandom.uuid
        Fx18s::constructNewFile(uuid)
        text = CommonUtils::editTextSynchronously("")
        nhash = Fx18s::putBlob3(uuid, text)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18s::setAttribute2(uuid, "uuid", uuid)
        Fx18s::setAttribute2(uuid, "mikuType", "Ax1Text")
        Fx18s::setAttribute2(uuid, "unixtime", unixtime)
        Fx18s::setAttribute2(uuid, "datetime", datetime)
        Fx18s::setAttribute2(uuid, "nhash", nhash)
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # Ax1Text::toString(uuid)
    def self.toString(uuid)
        nhash = Fx18s::getAttributeOrNull(uuid, "nhash")
        text = Fx18s::getBlobOrNull(uuid, nhash) # This should not be null
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
                nhash = Fx18s::getAttributeOrNull(uuid, "nhash")
                text = Fx18s::getBlobOrNull(uuid, nhash)
                text = CommonUtils::editTextSynchronously(text)
                nhash = Fx18s::putBlob3(uuid, text)
                Fx18s::setAttribute2(uuid, "nhash", nhash)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{Ax1Text::toString(uuid).green}' ? ") then
                    Fx18s::destroy(uuid)
                    break
                end
            end
        }
    end
end
