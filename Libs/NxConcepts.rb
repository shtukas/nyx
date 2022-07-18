
# encoding: UTF-8

class NxConcepts

    # ----------------------------------------------------------------------
    # IO

    # NxConcepts::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxConcept"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18File::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18File::getAttributeOrNull(objectuuid, "description")
        }
    end

    # NxConcepts::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxConcept")
            .map{|objectuuid| NxConcepts::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxConcepts::destroy(uuid)
    def self.destroy(uuid)
        Fx18Utils::destroyFx18EmitEvents(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxConcepts::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        uuid = SecureRandom.uuid

        Fx18Utils::makeNewFile(uuid)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxConcept")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    datetime)
        Fx18File::setAttribute2(uuid, "description", description)

        uuid
    end

    # ----------------------------------------------------------------------
    # Data

    # NxConcepts::toString(item)
    def self.toString(item)
        "(entity) #{item["description"]}"
    end
end
