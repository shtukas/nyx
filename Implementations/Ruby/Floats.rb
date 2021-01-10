
# encoding: UTF-8

class Floats

    # Floats::floats()
    def self.floats()
        NSCoreObjects::getSet("c1d07170-ed5f-49fe-9997-5cd928ae1928")
    end

    # Floats::toString(float)
    def self.toString(float)
        "[float] #{float["line"]}"
    end

    # Floats::issueFloatText(line)
    def self.issueFloatText(line)
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

    # Floats::issueFloatTextInteractivelyOrNull()
    def self.issueFloatTextInteractivelyOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
        Floats::issueFloatText(line)
    end

    # Floats::moveFloatToDxThread(float, dxthread)
    def self.moveFloatToDxThread(float, dxthread)
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
                "metric"           => 0.75 - indx.to_f/1000,
                "landing"          => lambda { Floats::landing(float) },
                "nextNaturalStep"  => lambda { Floats::nextNaturalStep(float) },
                "isRunning"          => Runner::isRunning?(uuid),
                "isRunningForLong"   => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600,
                "x-isFloat"          => true,
            }
        }
    end
end
