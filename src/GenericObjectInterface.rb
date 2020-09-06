
# encoding: UTF-8

class GenericObjectInterface

    # GenericObjectInterface::isAsteroid(object)
    def self.isAsteroid(object)
        object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398"
    end

    # GenericObjectInterface::isDataPoint(object)
    def self.isDataPoint(object)
        object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69"
    end

    # GenericObjectInterface::toString(object, shouldUseCachedVersion = true)
    def self.toString(object, shouldUseCachedVersion = true)
        if GenericObjectInterface::isAsteroid(object) then
            return Asteroids::toString(object)
        end
        if GenericObjectInterface::isDataPoint(object) then
            return NSDataPoint::toString(object, shouldUseCachedVersion)
        end
        puts object
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # GenericObjectInterface::applyDateTimeOrderToObjects(objects)
    def self.applyDateTimeOrderToObjects(objects)
        objects
            .map{|object|
                {
                    "object"   => object,
                    "datetime" => GenericObjectInterface::getObjectReferenceDateTime(object)
                }
            }
            .sort{|i1, i2|
                i1["datetime"] <=> i2["datetime"]
            }
            .map{|i| i["object"] }
    end

    # GenericObjectInterface::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        return object["referenceDateTime"] if object["referenceDateTime"]
        object["referenceDateTime"] = Time.at(object["unixtime"]).utc.iso8601
        NyxObjects2::put(object)
        object["referenceDateTime"]
    end

    # GenericObjectInterface::landing(object)
    def self.landing(object)
        if GenericObjectInterface::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if GenericObjectInterface::isDataPoint(object) then
            NSDataPoint::landing(object)
            return
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # GenericObjectInterface::accessopen(object)
    def self.accessopen(object)
        if GenericObjectInterface::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if GenericObjectInterface::isDataPoint(object) then
            NSDataPoint::accessopen(object)
            return
        end
        puts object
        raise "[error: ba6962cf-e003-4a69-b2fc-e98c289e72b7]"
    end

    # GenericObjectInterface::destroy(object)
    def self.destroy(object)
        if GenericObjectInterface::isAsteroid(object) then
            return
        end
        if GenericObjectInterface::isDataPoint(object) then
            NSDataPoint::destroy(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end
end
