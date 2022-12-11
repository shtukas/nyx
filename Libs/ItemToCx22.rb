
class ItemToCx22

    # -- Set -------------------------------------

    # ItemToCx22::set(itemuuid, cx22uuid)
    def self.set(itemuuid, cx22uuid)
        filepath = "#{Config::pathToDataCenter()}/Item-to-Cx22/#{itemuuid}"
        File.open(filepath, "w"){|f| f.write(cx22uuid) }
    end

    # ItemToCx22::interactivelySelectAndMapToCx22OrNothing(itemuuid)
    def self.interactivelySelectAndMapToCx22OrNothing(itemuuid)
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return if cx22.nil?
        ItemToCx22::set(itemuuid, cx22["uuid"])
    end

    # -- Get -------------------------------------

    # ItemToCx22::getOrNull(itemuuid)
    def self.getOrNull(itemuuid)
        filepath = "#{Config::pathToDataCenter()}/Item-to-Cx22/#{itemuuid}"
        return nil if !File.exists?(filepath)
        IO.read(filepath).strip
    end

    # ItemToCx22::getCx22OrNull(itemuuid)
    def self.getCx22OrNull(itemuuid)
        cx22uuid = ItemToCx22::getOrNull(itemuuid)
        return nil if cx22uuid.nil?
        ItemsManager::getOrNull("Cx22", cx22uuid)
    end

    # ItemToCx22::itemToCx22IncludingInteractiveAttempt(item)
    def self.itemToCx22IncludingInteractiveAttempt(item)
        cx22 = ItemToCx22::getCx22OrNull(item["uuid"])
        return cx22 if cx22
        puts "item: #{PolyFunctions::toString(item)}"
        cx22 = Cx22::interactivelySelectCx22OrNull()
        return nil if cx22.nil?
        ItemToCx22::set(item["uuid"], cx22["uuid"])
        cx22
    end

    # ItemToCx22::itemToCx22OrNull(item)
    def self.itemToCx22OrNull(item)
        cx22 = ItemToCx22::getCx22OrNull(item["uuid"])
        return nil if cx22.nil?
        Cx22::markHasItems(cx22)
        cx22
    end

    # ItemToCx22::garbageCollection(itemuuid)
    def self.garbageCollection(itemuuid)
        filepath = "#{Config::pathToDataCenter()}/Item-to-Cx22/#{itemuuid}"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end
end
