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
        position = NxTailStreams::frontPositionMinusOne()
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

    # NxTailStreams::viennaUrl(url)
    def self.viennaUrl(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        coredataref = "url:#{DatablobStore::put(url)}"
        position = NxTailStreams::frontPositionMinusOne()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTailStream",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        ObjectStore2::commit("NxTriages", item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTailStreams::toString(item)
    def self.toString(item)
        "(#{"%8.3f" % item["position"]}) #{item["description"]}"
    end

    # NxTailStreams::frontPositionMinusOne()
    def self.frontPositionMinusOne()
        ([0] + NxTailStreams::items().map{|item| item["position"] }).min - 1
    end

    # NxTailStreams::endPositionPlusOne()
    def self.endPositionPlusOne()
        ([0] + NxTailStreams::items().map{|item| item["position"] }).max + 1
    end

    # NxTailStreams::getFrontElementOrNull()
    def self.getFrontElementOrNull()
        NxTailStreams::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"]}
            .first
    end

    # NxTailStreams::getEndElementOrNull()s
    def self.getEndElementOrNull()
        NxTailStreams::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"]}
            .last
    end

    # --------------------------------------------------
    # Operations

    # NxTailStreams::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
