
# encoding: UTF-8

class Floats

    # Floats::floats()
    def self.floats()
        NSCoreObjects::getSet("c1d07170-ed5f-49fe-9997-5cd928ae1928")
    end

    # Floats::toString(float)
    def self.toString(float)
        if float["type"] == "line" then
            return "[float] line: #{float["line"]}"
        end
        if float["type"] == "text" then
            return "[float] text: location: #{float["location"]}"
        end
    end

    # Floats::issueFloatLine(line)
    def self.issueFloatLine(line)
        uuid = Miscellaneous::l22()
        object = {
            "uuid"     => uuid,
            "nyxNxSet" => "c1d07170-ed5f-49fe-9997-5cd928ae1928",
            "unixtime" => Time.new.to_f,
            "type"     => "line",
            "line"     => line
        }
        NSCoreObjects::put(object)
        object
    end

    # Floats::issueFloatText(text)
    def self.issueFloatText(text)
        uuid = Miscellaneous::l22()
        location = Miscellaneous::l22()
        KeyValueStore::set("/Users/pascal/Galaxy/DataBank/Catalyst/Floats/kvstore", location, text)
        object = {
            "uuid"     => uuid,
            "nyxNxSet" => "c1d07170-ed5f-49fe-9997-5cd928ae1928",
            "unixtime" => Time.new.to_f,
            "type"     => "text",
            "location" => location
        }
        NSCoreObjects::put(object)
        object
    end

    # Floats::interactivelyIssueFloatOrNull()
    def self.interactivelyIssueFloatOrNull()
        operations = ["line", "text"]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return nil if operation.nil?
        if operation == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return Floats::issueFloatLine(line)
        end
        if operation == "text" then
            text = Miscellaneous::editTextSynchronously("")
            return Floats::issueFloatText(text)
        end
    end

    # Floats::moveFloatToDxThread(float, dxthread)
    def self.moveFloatToDxThread(float, dxthread)
        if float["type"] == "line" then
            quark = {
                "uuid"              => float["uuid"],
                "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
                "unixtime"          => Time.new.to_f,
                "type"              => "line",
                "line"              => float["line"]                              
            }
            NSCoreObjects::put(quark)
            Arrows::issueOrException(dxthread, quark)
        end
        if float["type"] == "text" then
            puts "I do not know how to move floats of type text to DxThread"
            LucilleCore::pressEnterToContinue()
        end
    end

    # Floats::landing(float)
    def self.landing(float)
        puts Floats::toString(float)
        uuid = float["uuid"]
        operations = [
            "start",
            "destroy",
            "update description",
            "migrate to DxThread"
        ]
        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
        return if operation.nil?
        if operation == "start" then
            Runner::start(uuid)
        end
        if operation == "destroy" then
            NSCoreObjects::destroy(float)
        end
        if operation == "update description" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            float["line"] = description
            NSCoreObjects::put(float)
        end
        if operation == "migrate to DxThread" then
            dxthread = DxThreads::selectOneExistingDxThreadOrNull()
            return if dxthread.nil?
            if Runner::isRunning?(uuid) then
                timespan = Runner::stop(uuid)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                puts "sending #{timespan} to '#{DxThreads::toString(dxthread)}'"
                Bank::put(dxthread["uuid"], timespan)
            end
            # Now we convert the float to a quark and attach it to the threaf
            Floats::moveFloatToDxThread(float, dxthread)
        end
    end

    # Floats::nextNaturalStep(float)
    def self.nextNaturalStep(float)
        puts Floats::toString(float)
        uuid = float["uuid"]
        if Runner::isRunning?(uuid) then
            operations = [
                "stop",
                "stop and destroy",
                "migrate to DxThread"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "stop" then
                dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                return if dxthread.nil?
                timespan = Runner::stop(uuid)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                puts "sending #{timespan} to '#{DxThreads::toString(dxthread)}'"
                Bank::put(dxthread["uuid"], timespan)
            end
            if operation == "stop and destroy" then
                dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                return if dxthread.nil?
                timespan = Runner::stop(uuid)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                puts "sending #{timespan} to '#{DxThreads::toString(dxthread)}'"
                Bank::put(dxthread["uuid"], timespan)
                NSCoreObjects::destroy(float)
            end
            if operation == "migrate to DxThread" then
                dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                return if dxthread.nil?
                timespan = Runner::stop(uuid)
                timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                puts "sending #{timespan} to '#{DxThreads::toString(dxthread)}'"
                Bank::put(dxthread["uuid"], timespan)
                # Now we convert the float to a quark and attach it to the threaf
                Floats::moveFloatToDxThread(float, dxthread)
            end
        else
            operations = [
                "start",
                "destroy",
                "destroy with time added to DxThread",
                "migrate to DxThread"
            ]
            operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
            return if operation.nil?
            if operation == "start" then
                Runner::start(uuid)
            end
            if operation == "destroy" then
                NSCoreObjects::destroy(float)
            end
            if operation == "destroy with time added to DxThread" then
                dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                return if dxthread.nil?
                timespanInHours = LucilleCore::askQuestionAnswerAsString("time in hours: ").to_f
                puts "sending #{timespanInHours} hours to '#{DxThreads::toString(dxthread)}'"
                Bank::put(dxthread["uuid"], timespanInHours*3600)
                NSCoreObjects::destroy(float)
            end
            if operation == "migrate to DxThread" then
                dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                return if dxthread.nil?
                Floats::moveFloatToDxThread(float, dxthread)
            end

        end
    end

    # Floats::catalystObjects()
    def self.catalystObjects()
        Floats::floats()
        .sort{|f1, f2| f1["unixtime"] <=> f2["unixtime"] }
        .map
        .with_index{|float, indx|
            uuid = float["uuid"]
            {
                "uuid"             => uuid,
                "body"             => Floats::toString(float).yellow,
                "metric"           => 0.40 - indx.to_f/1000,
                "landing"          => lambda { Floats::landing(float) },
                "nextNaturalStep"  => lambda { Floats::nextNaturalStep(float) },
                "isRunning"          => Runner::isRunning?(uuid),
                "isRunningForLong"   => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600,
                "x-isFloat"          => true,
            }
        }
    end
end
