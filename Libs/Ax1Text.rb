
# encoding: UTF-8

class Ax1Text

    # ----------------------------------------------------------------------
    # IO

    # Ax1Text::items()
    def self.items()
        Librarian19InMemoryObjectDatabase::getObjectsByMikuType("Ax1Text")
    end

    # Ax1Text::itemsForOwner(owneruuid)
    def self.itemsForOwner(owneruuid)
        Ax1Text::items()
            .select{|item| item["owneruuid"] == owneruuid }
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
    end

    # Ax1Text::getOrNull(uuid): null or Ax1Text
    def self.getOrNull(uuid)
        Librarian19InMemoryObjectDatabase::getObjectByUUIDOrNull(uuid)
    end

    # Ax1Text::destroy(uuid)
    def self.destroy(uuid)
        Librarian19InMemoryObjectDatabase::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # Ax1Text::interactivelyIssueNewOrNullForOwner(owneruuid)
    def self.interactivelyIssueNewOrNullForOwner(owneruuid)
        text = Utils::editTextSynchronously("")
        nhash = InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::putBlob(text)
        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i
        item = {
          "uuid"        => uuid,
          "mikuType"    => "Ax1Text",
          "owneruuid"   => owneruuid,
          "unixtime"    => unixtime,
          "nhash"       => nhash
        }
        Librarian19InMemoryObjectDatabase::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # Ax1Text::toString(item)
    def self.toString(item)
        nhash = item["nhash"]
        text = InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
        description = (text != "") ? text.lines.first : "(empty text)"
        "(note) #{description}"
    end

    # ----------------------------------------------------------------------
    # Operations

    # Ax1Text::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()
            puts Ax1Text::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                nhash = item["nhash"]
                text = InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
                text = Utils::editTextSynchronously(text)
                nhash = InfinityDatablobs_XCacheAndInfinityBufferOut_ThenDriveLookupWithLocalXCaching::putBlob(text)
                item["nhash"] = nhash
                Librarian19InMemoryObjectDatabase::commit(item)
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
