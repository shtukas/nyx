# encoding: UTF-8

class NxFrames

    # NxFrames::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxFrame")
    end

    # NxFrames::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyClique(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxFrames::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxFrame",
            "description" => description,
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxFrames::toString(item)
    def self.toString(item)
        nx111String = item["nx111"] ? " (#{Nx111::toStringShort(item["nx111"])})" : ""
        "(frame) #{item["description"]}#{nx111String}"
    end

    # NxFrames::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(frame) #{item["description"]}"
    end

    # NxFrames::nx20s()
    def self.nx20s()
        NxFrames::items().map{|item|
            {
                "announce" => NxFrames::toStringForSearch(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
