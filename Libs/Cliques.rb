class Cliques

    # Cliques::findRemovableObjectOrNull(objects)
    def self.findRemovableObjectOrNull(objects)
        objects.combination(2).each{|pair|
            obj1, obj2 = pair
            if Genealogy::object1ShouldBeReplacedByObject2(obj1, obj2) then
                return obj1
            end
            if Genealogy::object1ShouldBeReplacedByObject2(obj2, obj1) then
                return obj2
            end
        }
        nil
    end

    # Cliques::performGarbageCollection(objects, killer)
    def self.performGarbageCollection(objects, killer)
        loop {
            obj = Cliques::findRemovableObjectOrNull(objects)
            return objects if obj.nil?
            killer.call(obj)
            objects = objects.reject{|object| object["uuid"] == obj["uuid"] }
        }
        objects
    end

    # Cliques::garbageCollectLocalClique(uuid)
    def self.garbageCollectLocalClique(uuid)
        clique = Librarian::getClique(uuid)
        Cliques::performGarbageCollection(clique, lambda{|item| Librarian::destroyVariantNoEvent(item["variant"]) })
    end

    # Cliques::garbageCollectCentralClique(uuid)
    def self.garbageCollectCentralClique(uuid)
        clique = StargateCentralObjects::getClique(uuid)
        Cliques::performGarbageCollection(clique, lambda{|item| StargateCentralObjects::destroyVariantNoEvent(item["variant"]) })
    end
end
