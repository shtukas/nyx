
class NxOpens

    # NxOpens::items()
    def self.items()
        ObjectStore2::objects("NxOpens")
    end

    # NxOpens::commit(item)
    def self.commit(item)
        ObjectStore2::commit("NxOpens", item)
    end

    # NxOpens::destroy(uuid)
    def self.destroy(uuid)
        ObjectStore2::destroy("NxOpens", uuid)
    end

    # NxOpens::interactivelyIssueNullOrNull()
    def self.interactivelyIssueNullOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOpen",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description
        }
        puts JSON.pretty_generate(item)
        NxOpens::commit(item)
        item
    end

    # NxOpens::toString(item)
    def self.toString(item)
        "(open) #{item["description"]}"
    end

    # NxOpens::itemsForBoard(boarduuid)
    def self.itemsForBoard(boarduuid)
        NxOpens::items().select{|item| item["boarduuid"] == boarduuid }
    end
end