
# encoding: UTF-8

class NxDataNodes

    # ----------------------------------------------------------------------
    # IO

    # NxDataNodes::items()
    def self.items()
        Librarian::getObjectsByMikuType("NxDataNode")
    end

    # NxDataNodes::destroy(uuid)
    def self.destroy(uuid)
        Librarian::destroyEntity(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # NxDataNodes::interactivelyIssueNewItemOrNull()
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        uuid = SecureRandom.uuid

        nx111 = Nx111::interactivelyCreateNewNx111OrNull(uuid)

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # NxDataNodes::issueNewItemAionPointFromLocation(location)
    def self.issueNewItemAionPointFromLocation(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx111 = Nx111::locationToAionPointNx111OrNull(uuid, location)
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        item = {
            "uuid"        => uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # NxDataNodes::issuePrimitiveFileFromLocationOrNull(location)
    def self.issuePrimitiveFileFromLocationOrNull(location)
        description = nil

        uuid = SecureRandom.uuid

        nx111 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(uuid, location)

        flavour = {
            "type" => "pure-data"
        }

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        item = {
            "uuid"        => uuid,
            "variant"     => SecureRandom.uuid,
            "mikuType"    => "NxDataNode",
            "unixtime"    => unixtime,
            "datetime"    => datetime,
            "description" => description,
            "nx111"       => nx111
        }
        Librarian::commit(item)
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # NxDataNodes::toString(item)
    def self.toString(item)
        "(data) #{item["description"]}"
    end

    # ------------------------------------------------
    # Nx20s

    # NxDataNodes::nx20s()
    def self.nx20s()
        NxDataNodes::items()
            .select{|item| !item["description"].nil? }
            .map{|item| 
                {
                    "announce" => "(#{item["uuid"][0, 4]}) #{NxDataNodes::toString(item)}",
                    "unixtime" => item["unixtime"],
                    "payload"  => item
                }
            }
    end
end
