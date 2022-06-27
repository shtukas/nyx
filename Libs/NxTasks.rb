# encoding: UTF-8

class NxTask

    # NxTask::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxTask")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # NxTask::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # --------------------------------------------------
    # Makers

    # --------------------------------------------------
    # Data

    # NxTask::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(task) #{item["description"]}#{nx111String}"
    end

    # NxTask::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTask::nx20s()
    def self.nx20s()
        NxTask::items()
            .map{|item|
                {
                    "announce" => NxTask::toStringForSearch(item),
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end

    # --------------------------------------------------
    # Operations

    

    # --------------------------------------------------
end
