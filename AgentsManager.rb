
# encoding: UTF-8

# AgentsManager::agents()
# AgentsManager::agentuuid2AgentData(agentuuid)
# AgentsManager::generalFlockUpgrade()

class AgentsManager

    def self.agents()
        [
            {
                "agent-name"      => "Collections",
                "agent-uid"       => "e4477960-691d-4016-884c-8694db68cbfb",
                "general-upgrade" => lambda { AgentCollections::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| AgentCollections::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ AgentCollections::interface() }
            },
            {
                "agent-name"      => "DailyTimeAttribution",
                "agent-uid"       => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "general-upgrade" => lambda { DailyTimeAttribution::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| DailyTimeAttribution::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ DailyTimeAttribution::interface() }
            },
            {
                "agent-name"      => "Ninja",
                "agent-uid"       => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "general-upgrade" => lambda { Ninja::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Ninja::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ Ninja::interface() }
            },
            {
                "agent-name"      => "Stream",
                "agent-uid"       => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "general-upgrade" => lambda { Stream::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Stream::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ Stream::interface() }
            },
            {
                "agent-name"      => "TimeCommitments",
                "agent-uid"       => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "general-upgrade" => lambda { TimeCommitments::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| TimeCommitments::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ TimeCommitments::interface() }
            },
            {
                "agent-name"      => "Today",
                "agent-uid"       => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "general-upgrade" => lambda { Today::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Today::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ Today::interface() }
            },
            {
                "agent-name"      => "Vienna",
                "agent-uid"       => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "general-upgrade" => lambda { Vienna::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Vienna::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ Vienna::interface() }
            },
            {
                "agent-name"      => "Wave",
                "agent-uid"       => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "general-upgrade" => lambda { Wave::generalFlockUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Wave::processObjectAndCommandFromCli(object, command) },
                "interface"       => lambda{ Wave::interface() }
            }
        ]
    end

    def self.agentuuid2AgentData(agentuuid)
        AgentsManager::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .first
    end

    def self.generalFlockUpgrade()
        AgentsManager::agents().each{|agentinterface| agentinterface["general-upgrade"].call() }
    end
end

