class Variants

    # Variants::findRemovableObjectOrNull(objects)
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

    # Variants::performGarbageCollection(objects, killer)
    def self.performGarbageCollection(objects, killer)
        loop {
            obj = Variants::findRemovableObjectOrNull(objects)
            return objects if obj.nil?
            killer.call(obj)
            objects = objects.reject{|object| object["uuid"] == obj["uuid"] }
        }
        objects
    end
end
