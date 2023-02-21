# encoding: UTF-8

class NxTails

    # NxTails::items()
    def self.items()
        ObjectStore2::objects("NxTails")
    end

    # NxTails::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTails", item)
    end

    # NxTails::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTails", uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTails::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        position = NxList::midposition()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTail",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "field11"     => coredataref,
            "position"    => boardposition
        }
        NxTails::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTails::toString(item)
    def self.toString(item)
        "(#{"%8.3f" % item["position"]}) #{item["description"]}"
    end

    # NxTails::frontPosition()
    def self.frontPosition()
        ([0] + NxTails::items().map{|item| item["position"] }).min
    end

    # NxTails::getFrontElementOrNull()
    def self.getFrontElementOrNull()
        NxTails::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"]}
            .first
    end

    # NxTails::getEndElementOrNull()
    def self.getEndElementOrNull()
        NxTails::items()
            .sort{|i1, i2| i1["position"] <=> i2["position"]}
            .last
    end

    # --------------------------------------------------
    # Operations

    # NxTails::access(item)
    def self.access(item)
        CoreData::access(item["field11"])
    end
end
