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

    # NxTopStreams::interactivelyIssueNewOrNull(streamOpt)
    def self.interactivelyIssueNewOrNull(streamOpt)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        stream = streamOpt ? streamOpt : NxStreams::interactivelySelectOne()
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
        "(#{"%8.3f" % item["position"]}) #{item["description"]}"
    end

    # NxTopStreams::toStringForFirstItem(item)
    def self.toStringForFirstItem(item)
        "#{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxTopStreams::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
