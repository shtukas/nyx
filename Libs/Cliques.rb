class Cliques

    # Cliques::findremovableObjectOrNull(objects)
    def self.findremovableObjectOrNull(objects)
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

    # Cliques::reduceClique(objects, killer)
    def self.reduceClique(objects, killer)
        loop {
            obj = Cliques::findremovableObjectOrNull(objects)
            return objects if obj.nil?
            killer.call(obj)
            objects = objects.reject{|object| object["uuid"] == obj["uuid"] }
        }
    end
end
