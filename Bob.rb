
# encoding: UTF-8


$BOB_AGENTS_IDENTITIES = []

class Bob

    def self.registerAgent(data)
        $BOB_AGENTS_IDENTITIES << data
    end

    # Bob::agents()
    def self.agents()
        $BOB_AGENTS_IDENTITIES
    end

    # Bob::agentuuid2AgentDataOrNull(agentuuid)
    def self.agentuuid2AgentDataOrNull(agentuuid)
        Bob::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .first
    end
end

