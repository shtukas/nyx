# encoding: UTF-8

class AirTrafficControl

    # AirTrafficControl::defaultAgent()
    def self.defaultAgent()
        {
            "uuid" => "3AD70E36-826B-4958-95BF-02E12209C375",
            "name" => "Default Stream"
        }
    end

    # AirTrafficControl::agents()
    def self.agents()
        sas = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/AirTrafficControl")
                .select{|filepath| filepath[-5, 5] == ".json" }
                .map{|filepath| JSON.parse(IO.read(filepath)) }
        sas + [AirTrafficControl::defaultAgent()]
    end

    # AirTrafficControl::commitAgentToDisk(agent)
    def self.commitAgentToDisk(agent)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/AirTrafficControl/#{agent["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(agent))}
    end
end

class AirTrafficDataOperator

    def initialize()
        @isLoaded = false
    end

    def loadAgentXTsSorted()
        @agentXTs = AirTrafficControl::agents()
            .map{|agent|
                agent["recoveryTime"] = BankExtended::stdRecoveredDailyTimeInHours(agent["uuid"])
                agent
            }
            .sort{|agent1, agent2| agent1["recoveryTime"] <=> agent2["recoveryTime"] }
    end

    def loadIfNotLoaded()
        if !@isLoaded then
            loadAgentXTsSorted()
            @isLoaded = true
        end

    end

    def getAgentRecoveryTime(agent)
        loadIfNotLoaded()
        @agentXTs.select{|a| a["uuid"] == agent["uuid"] }.first["recoveryTime"]
    end

    def agentToMetricData(agent)
        loadIfNotLoaded()
        [@agentXTs[0]["uuid"] == agent["uuid"] ? "ns:important" : "ns:zone", getAgentRecoveryTime(agent)]
    end

    def getAgentByIdOrNull(uuid)
        loadIfNotLoaded()
        @agentXTs.select{|a| a["uuid"] == uuid }.first
    end
end

$AirTrafficDataOperator = AirTrafficDataOperator.new()

