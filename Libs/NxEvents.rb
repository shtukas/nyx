
# encoding: UTF-8

class NxEvents

    # ----------------------------------------------------------------------
    # IO

    # NxEvents::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxEvent"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18File::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18File::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => JSON.parse(Fx18File::getAttributeOrNull(objectuuid, "nx111")),
        }
    end

    # NxEvents::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxEvent")
            .map{|objectuuid| NxEvents::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxEvents::destroy(uuid)
    def self.destroy(uuid)
        Fx18Utils::destroyFx18Logically(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxEvents::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        unixtime   = Time.new.to_i
        datetime   = CommonUtils::interactiveDateTimeBuilder()
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxEvent")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    datetime)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
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
