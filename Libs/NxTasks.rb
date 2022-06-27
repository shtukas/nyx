# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxTask")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # --------------------------------------------------
    # Makers

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

    # --------------------------------------------------
    # Operations

    

    # --------------------------------------------------
end
