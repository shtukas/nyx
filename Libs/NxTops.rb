
class NxTops

    # NxTops::items()
    def self.items()
        ObjectStore2::objects("NxTops")
    end

    # NxTops::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxTop",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
        }
        puts JSON.pretty_generate(item)
        ObjectStore2::commit("NxTops", item)
        ItemToTimeCommitmentMapping::interactiveProposalToSetMapping(item)
        item
    end

    # NxTops::toString(item)
    def self.toString(item)
        "(top) #{item["description"]}"
    end
end