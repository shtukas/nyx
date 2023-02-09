# encoding: UTF-8

class NxTailStreams

    # NxTailStreams::items()
    def self.items()
        ObjectStore2::objects("NxTailStreams")
    end

    # NxTailStreams::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTailStreams", item)
    end

    # NxTailStreams::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTailStreams", uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTailStreams::interactivelyIssueNewOrNull(streamOpt)
    def self.interactivelyIssueNewOrNull(streamOpt)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = 0
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTailStream",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => boardposition
        }
        NxTailStreams::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTailStreams::toString(item)
    def self.toString(item)
        "(#{"%8.3f" % item["position"]}) #{item["description"]}"
    end

    # NxTailStreams::toStringForFirstItem(item)
    def self.toStringForFirstItem(item)
        "#{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # NxTailStreams::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
