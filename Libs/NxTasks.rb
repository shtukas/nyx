# encoding: UTF-8

class NxTasks

    # NxTasks::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "NxTask"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "nx111"       => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "nx111")),
        }
    end

    # NxTasks::items()
    def self.items()
        Lookup1::mikuTypeToItems("NxTask")
    end

    # NxTasks::items2(count)
    def self.items2(count)
        Lookup1::mikuTypeToItems2("NxTask", count)
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)
        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "NxTask")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        Fx18Attributes::set_objectMaking(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
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
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "NxTask")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        Fx18Attributes::set_objectMaking(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        item = NxTasks::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 421cc48c-707a-4811-9bd9-7b1e56b689fa) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        nx111 = {
            "uuid" => SecureRandom.uuid,
            "type" => "url",
            "url"  => url
        }
        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "NxTask")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_i)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        Fx18Attributes::set_objectMaking(uuid, "nx111",       JSON.generate(nx111))
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        item = NxTasks::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: f78008bf-12d4-4483-b4bb-96e3472d46a2) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : " (line)"
            "(task)#{nx111String} #{item["description"]}"
        }
        builder.call()
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::section2()
    def self.section2()
        NxTasks::items2(10)
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            .select{|item| !TxProjects::uuidIsProjectElement(item["uuid"]) }
            .map{|item|
                {
                    "item" => item,
                    "toString" => NxTasks::toStringForSearch(item),
                    "metric"   => 0.6 + Catalyst::idToSmallShift(item["uuid"])
                }
            }
    end
end
