
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
        "agent-name"  => "Streams",
        "agentuid"    => "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1",
        "get-objects" => lambda { NSXAgentStreams::getObjects() },
        "get-objects-all" => lambda { NSXAgentStreams::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentStreams::processObjectAndCommand(object, command) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "TodayNotes",
        "agentuid"    => "f7b21eb4-c249-4f0a-a1b0-d5d584c03316",
        "get-objects" => lambda { NSXAgentDesktopLucilleFile::getObjects() },
        "get-objects-all" => lambda { NSXAgentDesktopLucilleFile::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentDesktopLucilleFile::processObjectAndCommand(object, command) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Vienna",
        "agentuid"    => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
        "get-objects" => lambda { NSXAgentVienna::getObjects() },
        "get-objects-all" => lambda { NSXAgentVienna::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentVienna::processObjectAndCommand(object, command) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Wave",
        "agentuid"    => "283d34dd-c871-4a55-8610-31e7c762fb0d",
        "get-objects" => lambda { NSXAgentWave::getObjects() },
        "get-objects-all" => lambda { NSXAgentWave::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentWave::processObjectAndCommand(object, command) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "NSXAgentTheBridgeCLIs",
        "agentuid"    => "d2422ba0-88e9-4abb-9ab9-6d609015268f",
        "get-objects" => lambda { NSXAgentTheBridgeCLIs::getObjects() },
        "get-objects-all" => lambda { NSXAgentTheBridgeCLIs::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentTheBridgeCLIs::processObjectAndCommand(object, command) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "NSXAgentBackupsMonitor",
        "agentuid"    => "9fad55cf-3f41-45ae-b480-5cbef40ce57f",
        "get-objects" => lambda { NSXAgentBackupsMonitor::getObjects() },
        "get-objects-all" => lambda { NSXAgentBackupsMonitor::getAllObjects() },
        "object-command-processor" => lambda{ |object, command| NSXAgentBackupsMonitor::processObjectAndCommand(object, command) },
        "interface"   => lambda { NSXAgentBackupsMonitor::interface() }
    }
)


