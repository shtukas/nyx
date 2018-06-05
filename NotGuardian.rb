
# encoding: UTF-8

# NotGuardian::registerAsNonGuardian(uuid)
# NotGuardian::isNonGuardian(uuid)
# NotGuardian::transform()

class NotGuardian
    def self.registerAsNonGuardian(uuid)
        DRbObject.new(nil, "druby://:18171").fKVStore_set("52282783-317c-41e4-be11-d4ecca5741c3:#{uuid}", "non-guardian")
    end
    def self.isNonGuardian(uuid)
        DRbObject.new(nil, "druby://:18171").fKVStore_getOrNull("52282783-317c-41e4-be11-d4ecca5741c3:#{uuid}") == "non-guardian"
    end
    def self.transform()
        aGuardianIsRunning = DRbObject.new(nil, "druby://:18171").flockOperator_flockObjects()
            .select{|object| object["agent-uid"]=="03a8bff4-a2a4-4a2b-a36f-635714070d1d" }
            .any?{|object| object["metadata"]["is-running"] }

        if aGuardianIsRunning then
            DRbObject.new(nil, "druby://:18171").flockOperator_flockObjects().each{|object|
                if self.isNonGuardian(object["uuid"]) then
                    object["metric"] = 0
                end
                DRbObject.new(nil, "druby://:18171").flockOperator_addOrUpdateObject(object)
            }
        end
    end
end
