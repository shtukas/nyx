
# encoding: UTF-8

class NyxObjectInterface

    # NyxObjectInterface::isAsteroid(object)
    def self.isAsteroid(object)
        object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398"
    end

    # NyxObjectInterface::isDataPoint(object)
    def self.isDataPoint(object)
        object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69"
    end

    # NyxObjectInterface::isCube(object)
    def self.isCube(object)
        object["nyxNxSet"] == "06071daa-ec51-4c19-a4b9-62f39bb2ce4f"
    end

    # NyxObjectInterface::isTag(object)
    def self.isTag(object)
        object["nyxNxSet"] == "287041db-39ac-464c-b557-2f172e721111"
    end

    # NyxObjectInterface::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # NyxObjectInterface::isListing(object)
    def self.isListing(object)
        object["nyxNxSet"] == "abb20581-f020-43e1-9c37-6c3ef343d2f5"
    end

    # NyxObjectInterface::toString(object)
    def self.toString(object)
        if NyxObjectInterface::isAsteroid(object) then
            return Asteroids::toString(object)
        end
        if NyxObjectInterface::isDataPoint(object) then
            return NGX15::toString(object)
        end
        if NyxObjectInterface::isCube(object) then
            return Cubes::toString(object)
        end
        if NyxObjectInterface::isTag(object) then
            return Tags::toString(object)
        end
        if NyxObjectInterface::isQuark(object) then
            return Quark::toString(object)
        end
        if NyxObjectInterface::isListing(object) then
            return Listings::toString(object)
        end
        puts object
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # NyxObjectInterface::applyDateTimeOrderToObjects(objects)
    def self.applyDateTimeOrderToObjects(objects)
        objects
            .map{|object|
                {
                    "object"   => object,
                    "datetime" => NyxObjectInterface::getObjectReferenceDateTime(object)
                }
            }
            .sort{|i1, i2|
                i1["datetime"] <=> i2["datetime"]
            }
            .map{|i| i["object"] }
    end

    # NyxObjectInterface::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        return object["referenceDateTime"] if object["referenceDateTime"]
        object["referenceDateTime"] = Time.at(object["unixtime"]).utc.iso8601
        NyxObjects2::put(object)
        object["referenceDateTime"]
    end

    # NyxObjectInterface::access(object)
    def self.access(object)
        if NyxObjectInterface::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if NyxObjectInterface::isDataPoint(object) then
            NGX15::landing(object)
            return
        end
        if NyxObjectInterface::isTag(object) then
            Tags::landing(set)
            return
        end
        if NyxObjectInterface::isCube(object) then
            Cubes::landing(object)
            return
        end
        if NyxObjectInterface::isQuark(object) then
            Quark::access(object)
            return
        end
        if NyxObjectInterface::isListing(object) then
            Listings::landing(object)
            return 
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # NyxObjectInterface::landing(object)
    def self.landing(object)
        if NyxObjectInterface::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if NyxObjectInterface::isDataPoint(object) then
            NGX15::landing(object)
            return
        end
        if NyxObjectInterface::isTag(object) then
            Tags::landing(set)
            return
        end
        if NyxObjectInterface::isCube(object) then
            Cubes::landing(object)
            return
        end
        if NyxObjectInterface::isQuark(object) then
            Quark::landing(object)
            return
        end
        if NyxObjectInterface::isListing(object) then
            Listings::landing(object)
            return 
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # NyxObjectInterface::destroy(object)
    def self.destroy(object)
        if NyxObjectInterface::isAsteroid(object) then
            Asteroids::asteroidTerminationProtocol(object)
            return
        end
        if NyxObjectInterface::isDataPoint(object) then
            NGX15::datapointTerminationProtocolReturnBoolean(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end
end
