
# encoding: UTF-8

class NxNavigation

    # NxNavigation::issue(description)
    def self.issue(description)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"        => SecureRandom.uuid,
            "mikuType"    => "NxNavigation",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description
        }
        Librarian::commit(item)
        item
    end

    # NxNavigation::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxNavigation::issue(description)
    end

    # NxNavigation::toString(item)
    def self.toString(item)
        "(nav) #{item["name"]}"
    end
end
