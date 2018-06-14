
# encoding: UTF-8

# Bob::agents()
# Bob::agentuuid2AgentData(agentuuid)
# Bob::generalFlockUpgrade()

class Bob

    @@agentsIdentities = []

    def self.registerAgent(data)
        @@agentsIdentities << data
    end

    def self.agents()
        @@agentsIdentities
    end

    def self.agentuuid2AgentData(agentuuid)
        Bob::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .first
    end

    def self.generalFlockUpgrade()
        Bob::agents().each{|agentinterface| agentinterface["general-upgrade"].call() }
    end
end

