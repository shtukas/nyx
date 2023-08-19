
class NyxNodes

    # NyxNodes::toString(item)
    def self.toString(item)
        if item["mikuType"] == "Nx101" then
            return Nx101s::toString(item)
        end
    end

    # NyxNodes::linkeduuids(item)
    def self.linkeduuids(item)
        if item["mikuType"] == "Nx101" then
            return item["linkeduuids"]
        end
    end

    # NyxNodes::taxonomy(item)
    def self.taxonomy(item)
        if item["mikuType"] == "Nx101" then
            return item["taxonomy"]
        end
    end

    # NyxNodes::notes(item)
    def self.notes(item)
        if item["mikuType"] == "Nx101" then
            return item["notes"]
        end
    end

    # NyxNodes::tags(item)
    def self.tags(item)
        if item["mikuType"] == "Nx101" then
            return []
        end
    end

    # NyxNodes::program(item)
    def self.program(item)
        if item["mikuType"] == "Nx101" then
            return Nx101s::program(item)
        end
    end

    # NyxNodes::allNetworkItems()
    def self.allNetworkItems()
        Cubes::mikuType('Nx101')
    end

    # NyxNodes::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Cubes::itemOrNull(uuid)
    end
end
