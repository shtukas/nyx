
# encoding: UTF-8


$BOB_AGENTS_IDENTITIES = []

class NSXBob

    def self.registerAgent(data)
        $BOB_AGENTS_IDENTITIES << data
    end

    # NSXBob::agents()
    def self.agents()
        $BOB_AGENTS_IDENTITIES
    end

    # NSXBob::agentuuid2AgentDataOrNull(agentuuid)
    def self.agentuuid2AgentDataOrNull(agentuuid)
        NSXBob::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
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
        "agent-name"  => "NSXAgentLightThread",
        "agent-uid"   => "201cac75-9ecc-4cac-8ca1-2643e962a6c6",
        "get-objects" => lambda { NSXAgentLightThread::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentLightThread::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentLightThread::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"      => "Ninja",
        "agent-uid"       => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
        "get-objects" => lambda { NSXAgentNinja::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentNinja::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentNinja::interface() }
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

NSXBob::registerAgent(
    {
        "agent-name"  => "WIS",
        "agent-uid"   => "3397e320-6c09-423d-ac58-2aea5f85eacb",
        "get-objects" => lambda { NSXAgentWIS::getObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentWIS::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentWIS::interface() }
    }
)



