
class NxEngine

    # NxEngine::types()
    def self.types()
        ["managed", "time-commitment"]
    end

    # NxEngine::interactivelyMakeNewEngineOrNull()
    def self.interactivelyMakeNewEngineOrNull()
        loop {
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("engine", NxEngine::types())
            next if type.nil?
            if type == "managed" then
                return {
                    "type" => "managed"
                }
            end
            if type == "time-commitment" then
                hours = LucilleCore::askQuestionAnswerAsString("hours (weekly): ").to_f
                return {
                    "type"          => "time-commitment",
                    "hours"         => hours,
                    "lastResetTime" => 0
                }
            end
            raise "(error: 6f880ecf-6253-4a0a-829c-58fb07cc2977) unsupported engine type: #{type}"
        }
    end

    # NxEngine::interactivelyMakeNewEngine()
    def self.interactivelyMakeNewEngine()
        loop {
            engine = NxEngine::interactivelyMakeNewEngineOrNull()
            return engine if engine
        }
    end
end
