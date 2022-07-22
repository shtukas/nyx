
# encoding: UTF-8

class NxCollections

    # ----------------------------------------------------------------------
    # IO

    # NxCollections::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxCollection"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description")
        }
    end

    # NxCollections::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxCollection")
            .map{|objectuuid| NxCollections::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxCollections::destroy(uuid)
    def self.destroy(uuid)
        Fx18Utils::destroyLocalFx18EmitEvents(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxCollections::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxCollection")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "datetime",    datetime)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckLocalObjectuuid(uuid)
        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxCollections::toString(item)
    def self.toString(item)
        "(collection) #{item["description"]}"
    end
end
