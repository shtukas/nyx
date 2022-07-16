
# encoding: UTF-8

class NxPersons

    # NxPersons::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
            "name"        => Fx18s::getAttributeOrNull(objectuuid, "name")
        }
        raise "(error: e7a6b562-65a1-4785-9337-63be3adabc3d) item: #{item}" if item["mikuType"] != "NxPerson"
        item
    end

    # NxPersons::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxPerson").map{|objectuuid|
            NxPersons::objectuuidToItem(objectuuid)
        }
    end

    # NxPersons::issue(name1)
    def self.issue(name1)
        uuid = SecureRandom.uuid
        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxPerson")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18s::setAttribute2(uuid, "name",        name1)
        uuid
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
