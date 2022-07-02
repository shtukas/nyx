# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxTask")
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        unixtime    = Time.new.to_i
        datetime    = Time.new.utc.iso8601

        item = {
            "uuid"        => SecureRandom.uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxTask",
            "description" => description,
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "nx111"       => nx111,
            "status"      => "active"
        }
        Librarian::commit(item)
        item
    end

    # NxTasks::issueFromInboxLocation(location)
    def self.issueFromInboxLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(location)
        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601
        item = {
          "uuid"         => uuid,
          "mikuType"     => "NxTask",
          "description"  => description,
          "unixtime"     => unixtime,
          "datetime"     => datetime,
          "nx111"        => nx111,
          "status"       => "inboxed"
        }
        Librarian::commit(item)
        item
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

        item = {
          "uuid"        => uuid,
          "mikuType"    => "NxTask",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111,
          "status"      => "inboxed"
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        data = XCache::getOrNull("cfbe45a9-aea6-4399-85b6-211d185f7f57:#{item["uuid"]}")
        if data then
            return data
        end
        builder = lambda{
            nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
            owner = Nx07::getOwnerForTaskOrNull(item)
            ownerstring = owner ? " (queue: #{owner["description"]})" : ""
            "(task) #{item["description"]}#{nx111String}#{ownerstring}"
        }
        data = builder.call()
        XCache::set("cfbe45a9-aea6-4399-85b6-211d185f7f57:#{item["uuid"]}", data) # string
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

    # NxTasks::itemsForMainListing()
    def self.itemsForMainListing()
        data = XCache::getOrNull("97e294c5-d00d-4be6-a4f6-f3a99d36bf83")
        if data then
            data = JSON.parse(data)
            return data.select{|item| Librarian::getClique(item["uuid"]).size > 0 }
        end
        builder = lambda {
            NxTasks::items()
                .select{|item| ["inboxed", "active"].include?(item["status"]) }
                .select{|item| Nx07::getOwnerForTaskOrNull(item).nil? }
                .partition{|item| item["status"] == "inboxed" }
                .flatten
        }
        data = builder.call()
        XCache::set("97e294c5-d00d-4be6-a4f6-f3a99d36bf83", JSON.generate(data))
        data
    end
end