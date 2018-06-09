
# encoding: UTF-8

# AgentsManager::agents()
# AgentsManager::agentuuid2AgentData(agentuuid)
# AgentsManager::generalFlockUpgrade()

class AgentsManager

    @@agentsIdentities = []

    def self.registerAgent(data)
        @@agentsIdentities << data
    end

    def self.agents()
        @@agentsIdentities
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

