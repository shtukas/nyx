
# encoding: UTF-8

$BOB_AGENTS_IDENTITIES = []

class NSXBob

    # NSXBob::registerAgent(data)
    def self.registerAgent(data)
        $BOB_AGENTS_IDENTITIES << data
    end

    # NSXBob::agents()
    def self.agents()
        $BOB_AGENTS_IDENTITIES
    end

    # NSXBob::getAgentDataByAgentUUIDOrNull(agentuuid)
    def self.getAgentDataByAgentUUIDOrNull(agentuuid)
        NSXBob::agents()
            .select{|agentinterface| agentinterface["agentuid"]==agentuuid }
            .first
    end

    # NSXBob::getAgentDataByAgentNameOrNull(agentname)
    def self.getAgentDataByAgentNameOrNull(agentname)
        NSXBob::agents()
            .select{|agentinterface| agentinterface["agent-name"]==agentname }
            .first
    end

end

NSXBob::registerAgent(
    {
        "agent-name"  => "BabyNights",
        "agentuid"    => "83837e64-554b-4dd0-a478-04386d8010ea",
        "get-objects" => lambda { NSXAgentBabyNights::getObjects() },
        "get-objects-all" => lambda { NSXAgentBabyNights::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentBabyNights::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentBabyNights::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "House",
        "agentuid"    => "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10",
        "get-objects" => lambda { NSXAgentHouse::getObjects() },
        "get-objects-all" => lambda { NSXAgentHouse::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentHouse::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentHouse::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Streams",
        "agentuid"    => "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1",
        "get-objects" => lambda { NSXAgentStreams::getObjects() },
        "get-objects-all" => lambda { NSXAgentStreams::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentStreams::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentStreams::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "TheBridge",
        "agentuid"    => "d2422ba0-88e9-4abb-9ab9-6d609015268f",
        "get-objects" => lambda { NSXAgentTheBridge::getObjects() },
        "get-objects-all" => lambda { NSXAgentTheBridge::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentTheBridge::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentTheBridge::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "TodayNotes",
        "agentuid"    => "f7b21eb4-c249-4f0a-a1b0-d5d584c03316",
        "get-objects" => lambda { NSXAgentTodayNotes::getObjects() },
        "get-objects-all" => lambda { NSXAgentTodayNotes::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentTodayNotes::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentTodayNotes::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Vienna",
        "agentuid"    => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
        "get-objects" => lambda { NSXAgentVienna::getObjects() },
        "get-objects-all" => lambda { NSXAgentVienna::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentVienna::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentVienna::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Wave",
        "agentuid"    => "283d34dd-c871-4a55-8610-31e7c762fb0d",
        "get-objects" => lambda { NSXAgentWave::getObjects() },
        "get-objects-all" => lambda { NSXAgentWave::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentWave::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentWave::interface() }
    }
)



