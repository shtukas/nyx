
# encoding: UTF-8

class EvaporatingWeights

    # EvaporatingWeights::getRatio(uuid)
    def self.getRatio(uuid)
        lastResetTime = KeyValueStore::getOrDefaultValue(nil, "d3ee3724-a6d1-4d2d-8912-81b47264251b:#{uuid}", "0").to_f
        1 - Math.exp( -(Time.new.to_i - lastResetTime).to_f/86400 )
    end

    # EvaporatingWeights::mark(uuid)
    def self.mark(uuid)
        KeyValueStore::set(nil, "d3ee3724-a6d1-4d2d-8912-81b47264251b:#{uuid}", Time.new.to_i)
    end

end

class Floats

    # Floats::floats()
    def self.floats()
        NSCoreObjects::getSet("c1d07170-ed5f-49fe-9997-5cd928ae1928")
    end

    # Floats::toString(float)
    def self.toString(float)
        "[float] #{float["line"]}"
    end

    # Floats::issueFloatTextInteractivelyOrNull()
    def self.issueFloatTextInteractivelyOrNull()
        line = LucilleCore::askQuestionAnswerAsString("line: ")
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

    # Floats::catalystObjects()
    def self.catalystObjects()
        Floats::floats()
        .map{|float|
            uuid = float["uuid"]
            {
                "uuid"             => uuid,
                "body"             => Floats::toString(float).yellow,
                "metric"           => 0.2 + 0.7*EvaporatingWeights::getRatio(uuid),
                "landing"          => lambda {
                    uuid = float["uuid"]
                    operations = [
                        "start",
                        "destroy"
                    ]
                    operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                    return if operation.nil?
                    if operation == "start" then
                        Runner::start(uuid)
                    end
                    if operation == "destroy" then
                        NSCoreObjects::destroy(float)
                    end
                },
                "nextNaturalStep"  => lambda {
                    uuid = float["uuid"]
                    if Runner::isRunning?(uuid) then
                        operations = [
                            "stop",
                            "stop and destroy"
                        ]
                        operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                        return if operation.nil?
                        if operation == "stop" then
                            dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                            timespan = Runner::stop(uuid)
                            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                            puts "sending #{timespan} to '#{DxThreads::toString(dxthread)}'"
                            Bank::put(dxthread["uuid"], timespan)
                        end
                        if operation == "stop and destroy" then
                            dxthread = DxThreads::selectOneExistingDxThreadOrNull()
                            timespan = Runner::stop(uuid)
                            timespan = [timespan, 3600*2].min # To avoid problems after leaving things running
                            puts "sending #{timespan} to '#{DxThreads::toString(dxthread)}'"
                            Bank::put(dxthread["uuid"], timespan)
                            NSCoreObjects::destroy(float)
                        end
                    else
                        Runner::start(uuid)
                    end
                },
                "isRunning"          => Runner::isRunning?(uuid),
                "isRunningForLong"   => (Runner::runTimeInSecondsOrNull(uuid) || 0) > 3600,
                "x-isFloat"          => true,
                "x-float-add-weight" => lambda { EvaporatingWeights::mark(uuid) }
            }
        }
    end
end
