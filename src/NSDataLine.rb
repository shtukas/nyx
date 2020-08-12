
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
            str = description
            KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::set(cacheKey, str)
            return str
        end
        if description.nil? and datapoints.size > 0 then
            str = "[dataline] [#{datapoints.size}] #{NSDataPoint::toString(datapoints.last)}"
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

    # NSDataLine::openLastDataPointOrNothing(dataline)
    def self.openLastDataPointOrNothing(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?
        NSDataPoint::openPoint(dataline, datapoint)
    end

    # NSDataLine::editLastDataPointOrNothing(dataline)
    def self.editLastDataPointOrNothing(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?
        newdatapoint = NSDataPoint::editPointReturnNewPointOrNull(dataline, datapoint)
        return if newdatapoint.nil?
        Arrows::issueOrException(dataline, newdatapoint)
    end

    # NSDataLine::accessLastDataPoint(dataline)
    def self.accessLastDataPoint(dataline)
        datapoint = NSDataLine::getDatalineLastDataPointOrNull(dataline)
        return if datapoint.nil?

        modes = ["access read only", "access edit", "destroy"]

        if datapoint["type"] == "text" then
            # By default we edit texts
            modes = ["access edit", "destroy"]
        end
        if datapoint["type"] == "aion-point" then
            # By default we edit aion-points
            modes = ["access edit", "destroy"]
        end
        if datapoint["type"] == "NyxFile" then
            NSDataLine::editLastDataPointOrNothing(dataline)
            return
        end
        if datapoint["type"] == "NyxPod" then
            # By default we edit NyxPods
            NSDataLine::editLastDataPointOrNothing(dataline)
            return
        end

        loop {
            mode = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", modes)
            return if mode.nil?
            if mode == "access read only" then
                NSDataLine::openLastDataPointOrNothing(dataline)
            end
            if mode == "access edit" then
                NSDataLine::editLastDataPointOrNothing(dataline)
            end
            if mode == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to do that? : ") then
                    NyxObjects::destroy(dataline)
                end
            end
        }
    end

    # NSDataLine::decacheObjectMetadata(dataline)
    def self.decacheObjectMetadata(dataline)
        KeyToJsonNSerialisbleValueInMemoryAndOnDiskStore::delete("a4f97e52-ce86-45ba-8f27-37c06c085d5b:#{dataline["uuid"]}")
        NSDataLine::getDatalineDataPointsInTimeOrder(dataline).each{|datapoint|
            NSDataPoint::decacheObjectMetadata(datapoint)
        }
    end

    # NSDataLine::getDatalineParents(dataline)
    def self.getDatalineParents(dataline)
        Arrows::getSourcesForTarget(dataline)
    end
end
