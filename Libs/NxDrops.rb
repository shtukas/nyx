
class NxDrops

    # NxDrops::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        uuid  = SecureRandom.uuid
        tc = NxTimeCommitments::interactivelySelectOneOrNull()
        item = {
            "uuid"             => uuid,
            "mikuType"         => "NxDrop",
            "unixtime"         => Time.new.to_i,
            "datetime"         => Time.new.utc.iso8601,
            "description"      => description,
            "field10"          => tc ? tc["uuid"] : nil, # tc uuid
            "field13"          => Engine::trajectory(Time.new.to_f, 48) # trajectory
        }
        puts JSON.pretty_generate(item)
        ObjectStore1::commitItem(item)
    end

    # NxDrops::toString(item)
    def self.toString(item)
        "(drop) #{item["description"]} (tc: #{NxTimeCommitments::uuidToDescription(item["field10"])})"
    end

end