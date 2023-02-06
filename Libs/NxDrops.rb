
class NxDrops

    # NxDrops::items()
    def self.items()
        ObjectStore2::objects("NxDrops")
    end

    # NxDrops::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxDrops", item)
    end

    # NxDrops::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxDrops", uuid)
    end

    # NxDrops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"             => uuid,
            "mikuType"         => "NxDrop",
            "unixtime"         => Time.new.to_i,
            "datetime"         => Time.new.utc.iso8601,
            "description"      => description
        }
        puts JSON.pretty_generate(item)
        NxDrops::commit(item)
        ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(item)
        item
    end

    # NxDrops::toString(item)
    def self.toString(item)
        "(drop) #{item["description"]}"
    end
end