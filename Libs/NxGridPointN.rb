
# encoding: UTF-8

class NxGridPointN

    # ------------------------------------------------
    # Basic IO

    # NxGridPointN::items()
    def self.items()
        TheBook::getObjects("#{Config::pathToDataCenter()}/NxGridPointN")
    end

    # NxGridPointN::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        TheBook::getObjectOrNull("#{Config::pathToDataCenter()}/NxGridPointN", uuid)
    end

    # NxGridPointN::commitObject(object)
    def self.commitObject(object)
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        TheBook::commitObjectToDisk("#{Config::pathToDataCenter()}/NxGridPointN", object)
    end

    # NxGridPointN::destroy(uuid)
    def self.destroy(uuid)
        TheBook::destroy("#{Config::pathToDataCenter()}/NxGridPointN", uuid)
    end

    # ------------------------------------------------
    # Makers

    # NxGridPointN::networkType1()
    def self.networkType1()
        ["Information", "Entity", "Concept", "Event", "Person", "Collection", "Timeline"]
    end

    # NxGridPointN::interactivelySelectNetworkType1()
    def self.interactivelySelectNetworkType1()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("networkType", NxGridPointN::networkType1())
        return type if type
        NxGridPointN::interactivelySelectNetworkType1()
    end

    # NxGridPointN::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        networkType1 = NxGridPointN::interactivelySelectNetworkType1()
        stateOpt = GridState::interactivelyBuildGridStateOrNull()
        states = [stateOpt].compact
        item = {
            "uuid"         => SecureRandom.uuid,
            "mikuType"     => "NxGridPointN",
            "unixtime"     => Time.new.to_f,
            "datetime"     => Time.new.utc.iso8601,
            "description"  => description,
            "networkType1" => networkType1,
            "states"       => states,
            "comments"     => []
        }
        FileSystemCheck::fsck_NxGridPointN(item, SecureRandom.hex, true)

        item
    end
end
