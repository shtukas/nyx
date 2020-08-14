
# encoding: UTF-8

class NSDataLine

    # NSDataLine::issue()
    def self.issue()
        object = {
            "uuid"     => SecureRandom.uuid,
            "nyxNxSet" => "d319513e-1582-4c78-a4c4-bf3d72fb5b2d",
            "unixtime" => Time.new.to_f,
        }
        NyxObjects::put(object)
        object
    end

    # NSDataLine::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxObjects::getOrNull(uuid)
    end

    # NSDataLine::datalines()
    def self.datalines()
        NyxObjects::getSet("d319513e-1582-4c78-a4c4-bf3d72fb5b2d")
    end

    # NSDataLine::toString(dataline)
    def self.toString(dataline)
        cacheKey = "a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}"
        str = KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::getOrNull(cacheKey)
        return str if str
        datapoints = NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
        description = NSDataTypeXExtended::getLastDescriptionForTargetOrNull(dataline)
        if description then
            typeToDisplayType = lambda {|type|
                return "picture(+)" if type == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1"
                type
            }
            str = "[data] [#{typeToDisplayType.call(datapoints.last["type"])}] #{description}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and datapoints.size > 0 then
            str = "[data] #{NSDataPoint::toStringForDataline(datapoints.last)}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and datapoints.size == 0 then
            str = "{no description, no data}"
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        raise "[error: 42f8a410-17c4-4130-91b8-bf60c7c10915]"
    end

    # NSDataLine::interactivelyAddNewDataPointToDatalineOrNothing(dataline)
    def self.interactivelyAddNewDataPointToDatalineOrNothing(dataline)
        ns0 = NSDataPoint::issueNewPointInteractivelyOrNull()
        return if ns0.nil?
        Arrows::issueOrException(dataline, ns0)
    end

    # NSDataLine::interactiveIssueNewDatalineWithItsFirstPointOrNull()
    def self.interactiveIssueNewDatalineWithItsFirstPointOrNull()
        dataline = NSDataLine::issue()
        NSDataLine::interactivelyAddNewDataPointToDatalineOrNothing(dataline)
        return nil if NSDataLine::getDatalineDataPointsInTimeOrder(dataline).empty?
        dataline
    end

    # NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
    def self.getDatalineDataPointsInTimeOrder(dataline)
        Arrows::getTargetsForSource(dataline)
            .select{|object| object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # NSDataLine::getDatalineLastDataPointOrNull(dataline)
    def self.getDatalineLastDataPointOrNull(dataline)
        NSDataLine::getDatalineDataPointsInTimeOrder(dataline)
            .last
    end

    # NSDataLine::enterLastDataPointOrNothing(dataline)
    def self.enterLastDataPointOrNothing(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        puts datapoint
        return if datapoint.nil?
        newdatapoint = NSDataPoint::readWriteDatalineDataPointReturnNewPointOrNull(dataline, datapoint)
        return if newdatapoint.nil?
        Arrows::issueOrException(dataline, newdatapoint)
    end

    # NSDataLine::landing(dataline)
    def self.landing(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?

        if ["line", "url", "text", "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1", "aion-point"].include?(datapoint["type"]) then
            modes = ["open", "destroy"]
            loop {
                mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
                return if mode.nil?
                if mode == "open" then
                    NSDataLine::enterLastDataPointOrNothing(dataline)
                end
                if mode == "destroy" then
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to do that? : ") then
                        NyxObjects::destroy(dataline)
                        return
                    end
                end
            }
            return
        end

        if ["NyxPod", "NyxFile"].include?(datapoint["type"]) then
            NSDataLine::enterLastDataPointOrNothing(dataline)
            return
        end

        raise "[NSDataPoint error 2c53b113-cc79]"
    end

    # NSDataLine::decacheObjectMetadata(dataline)
    def self.decacheObjectMetadata(dataline)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}")
    end

    # NSDataLine::getDatalineParents(dataline)
    def self.getDatalineParents(dataline)
        Arrows::getSourcesForTarget(dataline)
    end
end
