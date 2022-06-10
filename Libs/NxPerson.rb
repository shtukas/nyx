
# encoding: UTF-8

class NxPerson

    # NxPerson::issue(name1)
    def self.issue(name1)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"     => SecureRandom.uuid,
            "mikuType" => "NxPerson",
            "unixtime" => unixtime,
            "datetime" => datetime,
            "name"     => name1
        }
        Librarian::commit(item)
        item
    end

    # NxPerson::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("(person) name (empty to abort): ")
        return nil if name1
        NxPerson::issue(name1)
    end

    # NxPerson::toString(item)
    def self.toString(item)
        "(person) #{item["name"]}"
    end
end
