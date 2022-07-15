
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # IO

    # Ax1Text::items()
    def self.items()
        Librarian::getObjectsByMikuType("Ax1Text")
    end

    # Ax1Text::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::interactivelyIssueNewOrNullForOwner()
    def self.interactivelyIssueNewOrNullForOwner()
        uuid = SecureRandom.uuid
        Fx18s::constructNewFile(uuid)
        text = CommonUtils::editTextSynchronously("")
        nhash = Fx18s::putBlob3(uuid, text)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
          "uuid"     => uuid,
          "variant"  => SecureRandom.uuid,
          "mikuType" => "Ax1Text",
          "unixtime" => unixtime,
          "datetime" => datetime,
          "nhash"    => nhash
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Ax1Text::toString(item)
    def self.toString(item)
        text = Fx18s::getBlobOrNull(item["uuid"], item["nhash"]) # This should not be null
        description = (text != "") ? text.lines.first : "(empty text)"
        "(note) #{description}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Ax1Text::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            puts Ax1Text::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                nhash = item["nhash"]
                text = Fx18s::getBlobOrNull(item["uuid"], nhash)
                text = CommonUtils::editTextSynchronously(text)
                nhash = Fx18s::putBlob3(item["uuid"], text)
                item["nhash"] = nhash
                Librarian::commit(item)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{Ax1Text::toString(item).green}' ? ") then
                    Ax1Text::destroy(item["uuid"])
                    break
                end
            end
        }
    end
end
