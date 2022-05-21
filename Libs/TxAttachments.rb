
# encoding: UTF-8

class TxAttachments

    # ----------------------------------------------------------------------
    # IO

    # TxAttachments::items()
    def self.items()
        Librarian20ObjectsStore::getObjectsByMikuType("TxAttachment")
    end

    # TxAttachments::itemsForOwner(owneruuid)
    def self.itemsForOwner(owneruuid)
        TxAttachments::items()
            .select{|item| item["owneruuid"] == owneruuid }
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
    end

    # TxAttachments::getOrNull(uuid): null or TxAttachment
    def self.getOrNull(uuid)
        Librarian20ObjectsStore::getObjectByUUIDOrNull(uuid)
    end

    # TxAttachments::destroy(uuid)
    def self.destroy(uuid)
        Librarian20ObjectsStore::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # TxAttachments::interactivelyIssueNewOrNullForOwner(owneruuid)
    def self.interactivelyIssueNewOrNullForOwner(owneruuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx111 = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfNyxNodesAttachment())
        return nil if nx111.nil?

        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxAttachment",
          "owneruuid"   => owneruuid,
          "unixtime"    => unixtime,
          "description" => description,
          "iam"         => nx111
        }
        Librarian20ObjectsStore::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TxAttachments::toString(item)
    def self.toString(item)
        "(attachment) #{item["description"]} (#{item["iam"]["type"]})"
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxAttachments::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            Sx01Snapshots::printSnapshotDeploymentStatusIfRelevant()
            puts TxAttachments::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                EditionDesk::exportItemToDeskIfNotAlreadyExportedAndAccess(item)
            end
            if operation == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroy of '#{TxAttachments::toString(item)}' ? ") then
                    TxAttachments::destroy(item["uuid"])
                    break
                end
            end
        }
    end
end
