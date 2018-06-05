
# encoding: UTF-8

# AgentsManager::agents()
# AgentsManager::agentuuid2AgentData(agentuuid)
# AgentsManager::generalUpgradeFromFlockServer()

class AgentsManager

    def self.agents()
        [
            {
                "agent-name"      => "Collections",
                "agent-uid"       => "e4477960-691d-4016-884c-8694db68cbfb",
                "general-upgrade" => lambda { AgentCollections::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| AgentCollections::processObjectAndCommand(object, command) },
                "interface"       => lambda{ AgentCollections::interface() }
            },
            {
                "agent-name"      => "DailyTimeAttribution",
                "agent-uid"       => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "general-upgrade" => lambda { DailyTimeAttribution::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| DailyTimeAttribution::processObjectAndCommand(object, command) },
                "interface"       => lambda{ DailyTimeAttribution::interface() }
            },
            {
                "agent-name"      => "Ninja",
                "agent-uid"       => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "general-upgrade" => lambda { Ninja::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| Ninja::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Ninja::interface() }
            },
            {
                "agent-name"      => "Stream",
                "agent-uid"       => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "general-upgrade" => lambda { Stream::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| Stream::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Stream::interface() }
            },
            {
                "agent-name"      => "TimeCommitments",
                "agent-uid"       => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "general-upgrade" => lambda { TimeCommitments::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| TimeCommitments::processObjectAndCommand(object, command) },
                "interface"       => lambda{ TimeCommitments::interface() }
            },
            {
                "agent-name"      => "Today",
                "agent-uid"       => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "general-upgrade" => lambda { Today::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| Today::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Today::interface() }
            },
            {
                "agent-name"      => "Vienna",
                "agent-uid"       => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "general-upgrade" => lambda { Vienna::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| Vienna::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Vienna::interface() }
            },
            {
                "agent-name"      => "Wave",
                "agent-uid"       => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "general-upgrade" => lambda { Wave::generalUpgradeFromFlockServer() },
                "object-command-processor"  => lambda{ |object, command| Wave::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Wave::interface() }
            }
        ]
    end

    def self.agentuuid2AgentData(agentuuid)
        AgentsManager::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .first
    end

    def self.generalUpgradeFromFlockServer()
        AgentsManager::agents().each{|agentinterface| agentinterface["general-upgrade"].call() }
    end
end

