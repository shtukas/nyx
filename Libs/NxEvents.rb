
# encoding: UTF-8

class NxEvents

    # ----------------------------------------------------------------------
    # IO

    # NxEvents::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxEvent")
    end

    # NxEvents::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyEntity(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEvents::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)

        unixtime   = Time.new.to_i
        datetime   = CommonUtils::interactiveDateTimeBuilder()

        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxEvent")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    datetime)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxEvents::toString(item)
    def self.toString(item)
        "(event) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxEvents::nx20s()
    def self.nx20s()
        NxEvents::items()
            .select{|item| !item["description"].nil? }
            .map{|item| 
                {
                    "announce" => "(#{item["uuid"][0, 4]}) #{NxEvents::toString(item)}",
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
