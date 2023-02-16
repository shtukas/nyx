# encoding: UTF-8

class NxProjects

    # NxProjects::items()
    def self.items()
        ObjectStore2::objects("NxProjects")
    end

    # NxProjects::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxProjects", item)
    end

    # NxProjects::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxProjects", uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxProjects::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = 1
        isActive = LucilleCore::askQuestionAnswerAsBoolean("is active ? ")
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxProject",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position,
            "isActive"    => isActive
        }
        NxProjects::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxProjects::toString(item)
    def self.toString(item)
        "(project: #{"%5.2f" % item["position"]}) #{item["description"]}"
    end

    # NxProjects::listingItems()
    def self.listingItems()
        NxProjects::items()
            .select{|item| item["isActive"] }
            .sort{|p1, p2| BankUtils::recoveredAverageHoursPerDay(p1["uuid"]) <=> BankUtils::recoveredAverageHoursPerDay(p2["uuid"]) }
    end

    # --------------------------------------------------
    # Operations

    # NxProjects::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
