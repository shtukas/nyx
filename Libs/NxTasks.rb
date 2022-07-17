# encoding: UTF-8

class NxTasks

    # NxTasks::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if !Fx18Utils::fileExists?(objectuuid)
        return nil if Fx18File::getAttributeOrNull(objectuuid, "mikuType") != "NxTask"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18File::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18File::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18File::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18File::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => JSON.parse(Fx18File::getAttributeOrNull(objectuuid, "nx111")),
        }
    end

    # NxTasks::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxTask")
            .map{|objectuuid| NxTasks::objectuuidToItemOrNull(objectuuid)}
            .compact
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyFx18Logically(uuid)
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
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        uuid
    end

    # NxTasks::issueFromInboxLocation(location)
    def self.issueFromInboxLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        Fx18Utils::makeNewFile(uuid)
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

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
        Fx18File::setAttribute2(uuid, "uuid",        uuid)
        Fx18File::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18File::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18File::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18File::setAttribute2(uuid, "description", description)
        Fx18File::setAttribute2(uuid, "nx111",       JSON.generate(nx111))
        uuid
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        data = XCache::getOrNull("cfbe45a9-aea6-4399-85b6-211d185f7f57:#{item["uuid"]}:#{CommonUtils::today()}")
        if data then
            return data
        end
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
            project = TxProjects::getProjectPerElementUUIDOrNull(item["uuid"])
            projectstring = project ? "(project: #{project["description"]}) " : ""
            "(task) #{projectstring}#{item["description"]}#{nx111String}"
        }
        data = builder.call()
        XCache::set("cfbe45a9-aea6-4399-85b6-211d185f7f57:#{item["uuid"]}:#{CommonUtils::today()}", data) # string
        data
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::nx20s()
    def self.nx20s()
        return []
        NxTasks::items()
            .map{|item|
                {
                    "announce" => "(#{item["uuid"][0, 4]}) #{NxTasks::toString(item)}",
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
