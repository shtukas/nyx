# encoding: UTF-8

class NxTopStreams

    # NxTopStreams::items()
    def self.items()
        ObjectStore2::objects("NxTopStreams")
    end

    # NxTopStreams::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTopStreams", item)
    end

    # NxTopStreams::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTopStreams", uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTopStreams::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = 0
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTopStream",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxTopStreams::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTopStreams::toString(item)
    def self.toString(item)
        "(stream) (#{"%8.3f" % item["position"]}) #{item["description"]}"
    end

    # NxTopStreams::endPosition()
    def self.endPosition()
        ([0] + NxTopStreams::items().map{|item| item["position"] }).max
    end

    # NxTopStreams::listingItems()
    def self.listingItems()
        NxTopStreams::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"] }
            .take(3)
            .sort{|i1, i2| BankUtils::recoveredAverageHoursPerDay(i1["uuid"]) <=> BankUtils::recoveredAverageHoursPerDay(i2["uuid"]) }
    end

    # --------------------------------------------------
    # Operations

    # NxTopStreams::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
