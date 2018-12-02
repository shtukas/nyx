
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
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
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
        "agent-uid"   => "83837e64-554b-4dd0-a478-04386d8010ea",
        "get-objects" => lambda { NSXAgentBabyNights::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentBabyNights::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentBabyNights::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "House",
        "agent-uid"   => "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10",
        "get-objects" => lambda { NSXAgentHouse::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentHouse::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentHouse::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "LightThreads",
        "agent-uid"   => "201cac75-9ecc-4cac-8ca1-2643e962a6c6",
        "get-objects" => lambda { NSXAgentLightThread::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentLightThread::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentLightThread::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Ninja",
        "agent-uid"   => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
        "get-objects" => lambda { NSXAgentNinja::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentNinja::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentNinja::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "OneLiners",
        "agent-uid"   => "ef7253ae-f890-4342-a1da-81ac8dbdb344",
        "get-objects" => lambda { NSXAgentOneLiners::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentOneLiners::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentOneLiners::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Streams",
        "agent-uid"   => "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1",
        "get-objects" => lambda { NSXAgentStreams::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentStreams::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentStreams::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "TodayNotes",
        "agent-uid"   => "f7b21eb4-c249-4f0a-a1b0-d5d584c03316",
        "get-objects" => lambda { NSXAgentTodayNotes::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentTodayNotes::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentTodayNotes::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Vienna",
        "agent-uid"   => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
        "get-objects" => lambda { NSXAgentVienna::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentVienna::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentVienna::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Wave",
        "agent-uid"   => "283d34dd-c871-4a55-8610-31e7c762fb0d",
        "get-objects" => lambda { NSXAgentWave::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentWave::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentWave::interface() }
    }
)



