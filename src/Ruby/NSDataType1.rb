
# encoding: UTF-8

class NSDataType1

    # NSDataType1::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "c18e8093-63d6-4072-8827-14f238975d04",
            "unixtime" => Time.new.to_f
        }
        NyxObjects::put(object)
        object
    end

    # NSDataType1::points()
    def self.points()
        NyxObjects::getSet("c18e8093-63d6-4072-8827-14f238975d04")
    end

    # NSDataType1::getPointOrNull(uuid)
    def self.getPointOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataType1::pointToString(point)
    def self.pointToString(point)
        cacheKey = "645001e0-dec2-4e7a-b113-5c5e93ec0e68:#{Miscellaneous::today()}:#{point["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str

        ns0s = NSDataType1::pointToFramesInTimeOrder(point)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(point)
        if description and ns0s.size > 0 then
            str = "[point] [#{point["uuid"][0, 4]}] [#{ns0s.last["type"]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description and ns0s.size == 0 then
            str = "[point] [#{point["uuid"][0, 4]}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size > 0 then
            str = "[point] [#{point["uuid"][0, 4]}] #{NSDataType0s::frameToString(ns0s.last)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and ns0s.size == 0 then
            str = "[point] [#{point["uuid"][0, 4]}] no description and no frame"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        "[point] [#{point["uuid"][0, 4]}] [error: 752a3db2 ; pathological point: #{point["uuid"]}]"
    end

    # NSDataType1::getPointReferenceUnixtime(ns)
    def self.getPointReferenceUnixtime(ns)
        DateTime.parse(NavigationTypes::getObjectReferenceDateTime(ns)).to_time.to_f
    end

    # NSDataType1::pointToFramesInTimeOrder(point)
    def self.pointToFramesInTimeOrder(point)
        Arrows::getTargetsOfGivenSetsForSource(point, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataType1::pointToLastFrameOrNull(point)
    def self.pointToLastFrameOrNull(point)
        NSDataType1::pointToFramesInTimeOrder(point)
            .last
    end

    # NSDataType1::giveDescriptionToPointInteractively(point)
    def self.giveDescriptionToPointInteractively(point)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        return if description == ""
        NSDataTypeXExtended::issueDescriptionForTarget(point, description)
    end

    # NSDataType1::issueNewPointAndItsFirstFrameInteractivelyOrNull()
    def self.issueNewPointAndItsFirstFrameInteractivelyOrNull()
        ns0 = NSDataType0s::issueNewNSDataType0InteractivelyOrNull()
        return nil if ns0.nil?
        point = NSDataType1::issue()
        Arrows::issueOrException(point, ns0)
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        if description == "" then
            NSDataTypeXExtended::issueDescriptionForTarget(point, description)
        end
        point
    end

    # NSDataType1::openLastPointFrame(point)
    def self.openLastPointFrame(point)
        frame = NSDataType1::pointToLastFrameOrNull(point)
        if frame.nil? then
            puts "I could not find any frames for this point. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::openFrame(point, frame)
    end

    # NSDataType1::editLastPointFrame(point)
    def self.editLastPointFrame(point)
        frame = NSDataType1::pointToLastFrameOrNull(point)
        if frame.nil? then
            puts "I could not find any frames for this point. Aborting"
            LucilleCore::pressEnterToContinue()
            return
        end
        NSDataType0s::editFrame(point, frame)
    end

    # NSDataType1::pointMatchesPattern(point, pattern)
    def self.pointMatchesPattern(point, pattern)
        return true if point["uuid"].downcase.include?(pattern.downcase)
        return true if NSDataType1::pointToString(point).downcase.include?(pattern.downcase)
        false
    end

    # NSDataType1::selectPointPerPattern(pattern)
    def self.selectPointPerPattern(pattern)
        NSDataType1::points()
            .select{|point| NSDataType1::pointMatchesPattern(point, pattern) }
    end

    # NSDataType1::pointDestroyProcedure(point)
    def self.pointDestroyProcedure(point)
        folderpath = DeskOperator::deskFolderpathForNSDataType1(point)
        if File.exists?(folderpath) then
            LucilleCore::removeFileSystemLocation(folderpath)
        end
        NyxObjects::destroy(point)
    end

    # ---------------------------------------------

    # NSDataType1::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        NSDataType1::selectPointPerPattern(pattern)
            .map{|point|
                {
                    "description"   => NSDataType1::pointToString(point),
                    "referencetime" => NSDataType1::getPointReferenceUnixtime(point),
                    "dive"          => lambda{ NavigationTypes::landing(point) }
                }
            }
    end
end
