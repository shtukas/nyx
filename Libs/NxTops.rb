
class NxTops

    # NxTops::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        tc = NxTimeCommitments::interactivelySelectOneOrNull()
        item = {
            "uuid"          => uuid,
            "mikuType"      => "NxTop",
            "unixtime"      => Time.new.to_i,
            "datetime"      => Time.new.utc.iso8601,
            "description"   => description,
            "field10"       => tc ? tc["uuid"] : nil,
        }
        puts JSON.pretty_generate(item)
        ObjectStore1::commitItem(item)
    end

    # NxTops::toString(item)
    def self.toString(item)
        "(top) #{item["description"]} (tc: #{NxTimeCommitments::uuidToDescription(item["field10"])})"
    end
end