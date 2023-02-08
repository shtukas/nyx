
class NxTops

    # NxTops::items()
    def self.items()
        ObjectStore2::objects("NxTops")
    end

    # NxTops::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxTops", item)
    end

    # NxTops::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxTops", uuid)
    end

    # NxTops::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTop",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "ordinal"     => ordinal
        }
        puts JSON.pretty_generate(item)
        NxTops::commit(item)
        NonNxTodoItemToStreamMapping::interactiveProposalToSetMapping(item)
        item
    end

    # NxTops::toString(item)
    def self.toString(item)
        "(top) #{"%5.2f" % item["ordinal"]} #{item["description"]}"
    end
end