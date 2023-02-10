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

    # NxTailStreams::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxStreamsCommon::midpoint()
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
        position = NxStreamsCommon::midpoint()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTailStream",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
        }
        NxTailStreams::commit(item)
        item
    end

    # NxTailStreams::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nhash = AionCore::commitLocationReturnHash(DatablobStoreElizabeth.new(), location)
        coredataref = "aion-point:#{nhash}"
        position = NxStreamsCommon::midpoint()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTailStream",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => position
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

    # NxTailStreams::frontPosition()
    def self.frontPosition()
        ([0] + NxTailStreams::items().map{|item| item["position"] }).min
    end

    # NxTailStreams::getFrontElementOrNull()
    def self.getFrontElementOrNull()
        NxTailStreams::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"]}
            .first
    end

    # NxTailStreams::getEndElementOrNull()
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
