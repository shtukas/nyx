j# encoding: UTF-8

class TxFloats

    # TxFloats::items()
    def self.items()
        Librarian::getObjectsByMikuType("TxFloat")
    end

    # TxFloats::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroy(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxFloats::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull()

        unixtime = Time.new.to_i
        datetime = Time.new.utc.iso8601

        item = {
          "uuid"        => uuid,
          "mikuType"    => "TxFloat",
          "description" => description,
          "unixtime"    => unixtime,
          "datetime"    => datetime,
          "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # --------------------------------------------------
    # toString

    # TxFloats::toString(item)
    def self.toString(item)
        "(item) #{item["description"]} (#{Nx111::toStringShort(item["nx111"])})"
    end

    # TxFloats::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(item) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxFloats::complete(item)
    def self.complete(item)
        TxFloats::destroy(item["uuid"])
    end

    # --------------------------------------------------

    # TxFloats::itemsForListing()
    def self.itemsForListing()
        Librarian::getObjectsByMikuType("TxFloat")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
    end

    # --------------------------------------------------

    # TxFloats::nx20s()
    def self.nx20s()
        TxFloats::items().map{|item|
            {
                "announce" => TxFloats::toStringForSearch(item),
                "unixtime" => item["unixtime"],
                "payload"  => item
            }
        }
    end
end
