
# DxFSNodes are nodes that come from the Dx37A protocol.
# They are stored in a database at 
# /Users/pascal/Galaxy/DataHub/Dx37A-Nyx-Bridge/bridge.sqlite3
# inventory: create table inventory (uuid string primary key, update_unixtime float, description string, tags string)

class DxFSNodes

    # DxFSNodes::items()
    def self.items()

    end

    # DxFSNodes::toString(item)
    def self.toString(item)
        "(dxfs) #{item["description"]}"
    end

    # DxFSNodes::linkeduuids(item)
    def self.linkeduuids(item)
        []
    end

    # DxFSNodes::taxonomy(item)
    def self.taxonomy(item)
        []
    end

    # DxFSNodes::notes(item)
    def self.notes(item)
        []
    end

    # DxFSNodes::tags(item)
    def self.tags(item)
        item["tags"]
    end

    # DxFSNodes::program(item)
    def self.program(item)
        puts "Program has not yet been implemented for DxFSNode"
        LucilleCore::pressEnterToContinue()
    end
end