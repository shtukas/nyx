
# encoding: UTF-8

class TxAttachments

    # ----------------------------------------------------------------------
    # IO

    # TxAttachments::items()
    def self.items()
        Librarian6Objects::getObjectsByMikuType("TxAttachment")
    end

    # TxAttachments::itemsForOwner(owneruuid)
    def self.itemsForOwner(owneruuid)
        TxAttachments::items()
            .select{|item| item["owneruuid"] == owneruuid }
            .sort{|a1, a2| a1["unixtime"] <=> a2["unixtime"] }
    end

    # TxAttachments::getOrNull(uuid): null or TxAttachment
    def self.getOrNull(uuid)
        Librarian6Objects::getObjectByUUIDOrNull(uuid)
    end

    # TxAttachments::destroy(uuid)
    def self.destroy(uuid)
        Librarian6Objects::destroy(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Management

    # TxAttachments::interactivelyCreateNewOrNullForOwner(owneruuid)
    def self.interactivelyCreateNewOrNullForOwner(owneruuid)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        iAmValue = Nx111::interactivelyCreateNewIamValueOrNull(Nx111::iamTypesForManualMakingOfNyxNodesAttachment())
        return nil if iAmValue.nil?

        uuid     = SecureRandom.uuid
        unixtime = Time.new.to_i

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxAttachment",
          "owneruuid"   => owneruuid,
          "unixtime"    => unixtime,
          "description" => description,
          "iam"         => iAmValue
        }
        Librarian6Objects::commit(item)
        item
    end

    # TxAttachments::selectExistingOrNull()
    def self.selectExistingOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(TxAttachments::items(), lambda{|item| "(#{item["uuid"][0, 4]}) #{TxAttachments::toString(item)}" })
    end

    # ----------------------------------------------------------------------
    # Data

    # TxAttachments::toString(item)
    def self.toString(item)
        "(attachment) #{item["description"]} (#{item["iam"][0]})"
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxAttachments::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            puts TxAttachments::toString(item)
            operations = [
                "access/edit",
                "destroy"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            break if operation.nil?
            if operation == "access/edit" then
                Nx111::accessIamData_PossibleMutationInStorage_ExportsAreTx46Compatible(item)
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
