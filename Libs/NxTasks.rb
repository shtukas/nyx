# encoding: UTF-8

class NxTasks

    # NxTasks::objectuuidToItem(objectuuid)
    def self.objectuuidToItem(objectuuid)
        item = {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18s::getAttributeOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18s::getAttributeOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18s::getAttributeOrNull(objectuuid, "datetime"),
            "description" => Fx18s::getAttributeOrNull(objectuuid, "description"),
            "nx111"       => JSON.parse(Fx18s::getAttributeOrNull(objectuuid, "nx111")),
        }
        raise "(error: 6f348583-af54-429a-bb95-d34fa74fa3d5) item: #{item}" if item["mikuType"] != "NxTask"
        item
    end

    # NxTasks::items()
    def self.items()
        Librarian::mikuTypeUUIDs("NxTask").map{|objectuuid|
            NxTasks::objectuuidToItem(objectuuid)
        }
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

        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

        uuid
    end

    # NxTasks::issueFromInboxLocation(location)
    def self.issueFromInboxLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

        uuid
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }

        Fx18s::ensureFile(uuid)
        Fx18s::setAttribute2(uuid, "uuid",        uuid)
        Fx18s::setAttribute2(uuid, "mikuType",    "NxTask")
        Fx18s::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Fx18s::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18s::setAttribute2(uuid, "description", description)
        Fx18s::setAttribute2(uuid, "nx111",       JSON.generate(nx111))

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
