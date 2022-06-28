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

    # NxTasks::issueFromLocation(location)
    def self.issueFromLocation(location)
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
          "status"       => "active"
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
          "status"      => "active"
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(task) #{item["description"]}#{nx111String}"
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::nx20s()
    def self.nx20s()
        NxTasks::items()
            .map{|item|
                {
                    "announce" => NxTasks::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end

    # NxTasks::itemsForMainListing()
    def self.itemsForMainListing()
        NxTasks::items()
            .select{|item| ["inboxed", "active"].include?(item["status"]) }
            .partition{|item| item["status"] == "inboxed" }
            .flatten
    end
end
