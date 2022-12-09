
class Cx22Mapping

    # -- Set -------------------------------------

    # Cx22Mapping::set(itemuuid, cx22uuid)
    def self.set(itemuuid, cx22uuid)
        filepath = "#{Config::pathToDataCenter()}/Item-to-Cx22/#{itemuuid}"
        File.open(filepath, "w"){|f| f.write(cx22uuid) }
    end

    # Cx22Mapping::interactivelySelectAndMapToCx22OrNothing(itemuuid)
    def self.interactivelySelectAndMapToCx22OrNothing(itemuuid)
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        Cx22Mapping::set(itemuuid, cx22["uuid"])
    end

    # -- Get -------------------------------------

    # Cx22Mapping::getOrNull(itemuuid)
    def self.getOrNull(itemuuid)
        filepath = "#{Config::pathToDataCenter()}/Item-to-Cx22/#{itemuuid}"
        return nil if !File.exists?(filepath)
        IO.read(filepath).strip
    end

    # Cx22Mapping::getCx22OrNull(itemuuid)
    def self.getCx22OrNull(itemuuid)
        cx22uuid = Cx22Mapping::getOrNull(itemuuid)
        return nil if cx22uuid.nil?
        Cx22::getOrNull(cx22uuid)
    end

    # Cx22Mapping::itemToCx22IncludingInteractiveAttempt(item)
    def self.itemToCx22IncludingInteractiveAttempt(item)
        cx22 = Cx22Mapping::getCx22OrNull(item["uuid"])
        return cx22 if cx22
        puts "item: #{PolyFunctions::toString(item)}"
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        Cx22Mapping::set(item["uuid"], cx22["uuid"])
        cx22
    end

    # Cx22Mapping::itemToCx22OrNull(item)
    def self.itemToCx22OrNull(item)
        cx22 = Cx22Mapping::getCx22OrNull(item["uuid"])
        return nil if cx22.nil?
        Cx22::markHasItems(cx22)
        cx22
    end

    # Cx22Mapping::garbageCollection(itemuuid)
    def self.garbageCollection(itemuuid)
        filepath = "#{Config::pathToDataCenter()}/Item-to-Cx22/#{itemuuid}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
