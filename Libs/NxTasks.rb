# encoding: UTF-8

class NxTasks

    # NxTasks::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxTask"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18Utils::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # NxTasks::items()
    def self.items()
        Fx18Index1::mikuType2objectuuids("NxTask")
            .map{|objectuuid| NxTasks::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Fx18Utils::destroyFx18EmitEvents(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        Fx18Attributes::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        
        item = NxTasks::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueFromInboxLocation(location)
    def self.issueFromInboxLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        Fx18Attributes::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

        uuid
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        Fx18Utils::makeNewFile(uuid)
        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }
        Fx18Attributes::setAttribute2(uuid, "uuid",        uuid)
        Fx18Attributes::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18Attributes::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::setAttribute2(uuid, "description", description)
        Fx18Attributes::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        uuid
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
            project = TxProjects::getProjectPerElementUUIDOrNull(item["uuid"])
            projectstring = project ? "(project: #{project["description"]}) " : ""
            "(task) #{projectstring}#{item["description"]}#{nx111String}"
        }
        builder.call()
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end
end
