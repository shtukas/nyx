
# encoding: UTF-8

class GenericNyxObject

    # GenericNyxObject::isNGX15(object)
    def self.isNGX15(object)
        object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69"
    end

    # GenericNyxObject::isQuark(object)
    def self.isQuark(object)
        object["nyxNxSet"] == "d65674c7-c8c4-4ed4-9de9-7c600b43eaab"
    end

    # GenericNyxObject::isTag(object)
    def self.isTag(object)
        object["nyxNxSet"] == "287041db-39ac-464c-b557-2f172e721111"
    end

    # GenericNyxObject::isOpsNode(object)
    def self.isOpsNode(object)
        object["nyxNxSet"] == "abb20581-f020-43e1-9c37-6c3ef343d2f5"
    end

    # GenericNyxObject::isEncyclopediaNode(object)
    def self.isEncyclopediaNode(object)
        object["nyxNxSet"] == "f1ae7449-16d5-41c0-a89e-f2a8e486cc99"
    end

    # GenericNyxObject::isAsteroid(object)
    def self.isAsteroid(object)
        object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398"
    end

    # GenericNyxObject::toString(object)
    def self.toString(object)
        if GenericNyxObject::isAsteroid(object) then
            return Asteroids::toString(object)
        end
        if GenericNyxObject::isNGX15(object) then
            return NGX15::toString(object)
        end
        if GenericNyxObject::isTag(object) then
            return Tags::toString(object)
        end
        if GenericNyxObject::isQuark(object) then
            return Quarks::toString(object)
        end
        if GenericNyxObject::isOpsNode(object) then
            return OperationalListings::toString(object)
        end
        if GenericNyxObject::isEncyclopediaNode(object) then
            return EncyclopediaListings::toString(object)
        end
        puts object
        raise "[error: d4c62cad-0080-4270-82a9-81b518c93c0e]"
    end

    # GenericNyxObject::applyDateTimeOrderToObjects(objects)
    def self.applyDateTimeOrderToObjects(objects)
        objects
            .map{|object|
                {
                    "object"   => object,
                    "datetime" => GenericNyxObject::getObjectReferenceDateTime(object)
                }
            }
            .sort{|i1, i2|
                i1["datetime"] <=> i2["datetime"]
            }
            .map{|i| i["object"] }
    end

    # GenericNyxObject::getObjectReferenceDateTime(object)
    def self.getObjectReferenceDateTime(object)
        return object["referenceDateTime"] if object["referenceDateTime"]
        object["referenceDateTime"] = Time.at(object["unixtime"]).utc.iso8601
        NyxObjects2::put(object)
        object["referenceDateTime"]
    end

    # GenericNyxObject::selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
    def self.selectOneTargetOrNullDefaultToSingletonWithConfirmation(object)
        targets = Arrows::getTargetsForSource(object)
        if targets.size == 0 then
            return nil
        end
        if targets.size == 1 then
            if LucilleCore::askQuestionAnswerAsBoolean("selecting target: '#{GenericNyxObject::toString(targets[0])}' confirm ? ", true) then
                return targets[0]
            end
            return nil
        end
        targets = GenericNyxObject::applyDateTimeOrderToObjects(targets)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("target", targets, lambda{|target| GenericNyxObject::toString(target) })
    end

    # GenericNyxObject::access(object)
    def self.access(object)
        if GenericNyxObject::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if GenericNyxObject::isNGX15(object) then
            NGX15::landing(object)
            return
        end
        if GenericNyxObject::isTag(object) then
            Tags::landing(set)
            return
        end
        if GenericNyxObject::isQuark(object) then
            Quarks::access(object)
            return
        end
        if GenericNyxObject::isOpsNode(object) then
            OperationalListings::landing(object)
            return 
        end
        if GenericNyxObject::isEncyclopediaNode(object) then
            EncyclopediaListings::landing(object)
            return
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # GenericNyxObject::landing(object)
    def self.landing(object)
        if GenericNyxObject::isAsteroid(object) then
            Asteroids::landing(object)
            return
        end
        if GenericNyxObject::isNGX15(object) then
            NGX15::landing(object)
            return
        end
        if GenericNyxObject::isTag(object) then
            Tags::landing(object)
            return
        end
        if GenericNyxObject::isQuark(object) then
            Quarks::landing(object)
            return
        end
        if GenericNyxObject::isOpsNode(object) then
            OperationalListings::landing(object)
            return
        end
        if GenericNyxObject::isEncyclopediaNode(object) then
            EncyclopediaListings::landing(object)
            return
        end
        puts object
        raise "[error: 710c5e92-6436-4ec8-8d3d-302bdf361104]"
    end

    # GenericNyxObject::destroy(object)
    def self.destroy(object)
        if GenericNyxObject::isAsteroid(object) then
            Asteroids::asteroidTerminationProtocol(object)
            return
        end
        if GenericNyxObject::isNGX15(object) then
            NGX15::ngx15TerminationProtocolReturnBoolean(object)
            return
        end
        puts object
        raise "[error: 09e17b29-8620-4345-b358-89c58c248d6f]"
    end
end
