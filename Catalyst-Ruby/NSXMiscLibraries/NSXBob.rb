
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

    # NSXBob::getAgentDataByAgentUUIDOrNull(agentuid)
    def self.getAgentDataByAgentUUIDOrNull(agentuid)
        NSXBob::agents()
            .select{|agentinterface| agentinterface["agentuid"]==agentuid }
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
        "agent-name"  => "Anniversaries",
        "agentuid"    => "639beee6-c12e-4cb8-bc9a-f7890fa95db0",
        "get-objects" => lambda { NSXAgentAnniversaries::getObjects() },
        "get-objects-all" => lambda { NSXAgentAnniversaries::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentAnniversaries::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "BackupsMonitor",
        "agentuid"    => "63027c23-6131-4230-b49b-d3f23aa5ff54",
        "get-objects" => lambda { NSXAgentBackupsMonitor::getObjects() },
        "get-objects-all" => lambda { NSXAgentBackupsMonitor::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentBackupsMonitor::processObjectAndCommand(objectuuid, command, isLocalCommand) },
        "interface"   => lambda { NSXAgentBackupsMonitor::interface() }
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "DailyGuardianWork",
        "agentuid"    => "a6d554fd-44bf-4937-8dc6-5c9f1dcdaeba",
        "get-objects" => lambda { NSXAgentDailyGuardianWork::getObjects() },
        "get-objects-all" => lambda { NSXAgentDailyGuardianWork::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentDailyGuardianWork::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "DailyTimeCommitments",
        "agentuid"    => "8b881a6f-33b7-497a-9293-2aaeefa16c18",
        "get-objects" => lambda { NSXAgentDailyTimeCommitments::getObjects() },
        "get-objects-all" => lambda { NSXAgentDailyTimeCommitments::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentDailyTimeCommitments::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "DesktopLucilleFile",
        "agentuid"    => "f7b21eb4-c249-4f0a-a1b0-d5d584c03316",
        "get-objects" => lambda { NSXAgentDesktopLucilleFile::getObjects() },
        "get-objects-all" => lambda { NSXAgentDesktopLucilleFile::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentDesktopLucilleFile::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Streams",
        "agentuid"    => "d2de3f8e-6cf2-46f6-b122-58b60b2a96f1",
        "get-objects" => lambda { NSXAgentStreams::getObjects() },
        "get-objects-all" => lambda { NSXAgentStreams::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentStreams::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "VideosStreamConsumptionMonitor",
        "agentuid"    => "a3b9934f-4b01-4fca-80a3-63eb2a521df0",
        "get-objects" => lambda { NSXAgentVideosStreamConsumptionMonitor::getObjects() },
        "get-objects-all" => lambda { NSXAgentVideosStreamConsumptionMonitor::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentVideosStreamConsumptionMonitor::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Vienna",
        "agentuid"    => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
        "get-objects" => lambda { NSXAgentVienna::getObjects() },
        "get-objects-all" => lambda { NSXAgentVienna::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentVienna::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "Wave",
        "agentuid"    => "283d34dd-c871-4a55-8610-31e7c762fb0d",
        "get-objects" => lambda { NSXAgentWave::getObjects() },
        "get-objects-all" => lambda { NSXAgentWave::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentWave::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)

NSXBob::registerAgent(
    {
        "agent-name"  => "DesktopFilesMonitor",
        "agentuid"    => "ec12c56b-9692-424e-bb17-220b9066407d",
        "get-objects" => lambda { NSXAgentDesktopFilesMonitor::getObjects() },
        "get-objects-all" => lambda { NSXAgentDesktopFilesMonitor::getAllObjects() },
        "object-command-processor" => lambda{ |objectuuid, command, isLocalCommand| NSXAgentDesktopFilesMonitor::processObjectAndCommand(objectuuid, command, isLocalCommand) },
    }
)
