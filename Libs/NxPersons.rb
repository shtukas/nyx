
# encoding: UTF-8

class NxPersons

    # NxPersons::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxPerson")
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
            "uuid"     => SecureRandom.uuid,
            "variant"  => SecureRandom.uuid,
            "mikuType" => "NxPerson",
            "unixtime" => unixtime,
            "datetime" => datetime,
            "name"     => name1
        }
        Librarian::commit(item)
        item
    end

    # NxPersons::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("(person) name (empty to abort): ")
        return nil if name1 == ""
        NxPersons::issue(name1)
    end

    # NxPersons::toString(item)
    def self.toString(item)
        "(person) #{item["name"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxPersons::nx20s()
    def self.nx20s()
        NxPersons::items().map{|item| 
            {
                "announce" => "(#{item["uuid"][0, 4]}) #{NxPersons::toString(item)}",
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
