
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
                    operations = [
                        "destroy"
                    ]
                    operation = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", operations)
                    return if operation.nil?
                    if operation == "destroy" then
                        NSCoreObjects::destroy(float)
                    end
                },
                "nextNaturalStep"  => lambda {
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{Floats::toString(float)}' ? ") then
                        NSCoreObjects::destroy(float)
                    end
                },
                "isRunning"          => false,
                "isRunningForLong"   => false,
                "x-isFloat"          => true,
                "x-float-add-weight" => lambda { EvaporatingWeights::mark(uuid) }
            }
        }
    end
end
