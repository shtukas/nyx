# encoding: UTF-8

class AirTrafficControl

    # AirTrafficControl::agents()
    def self.agents()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/AirTrafficControl")
            .select{|filepath| filepath[-5, 5] == ".json" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
    end

    # AirTrafficControl::commitAgentToDisk(agent)
    def self.commitAgentToDisk(agent)
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/AirTrafficControl/#{agent["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(agent))}
    end

    # AirTrafficControl::agentsForUUID(uuid)
    def self.agentsForUUID(uuid)
        agents = AirTrafficControl::agents().select{|agent| agent["itemsuids"].include?(uuid) }
        return agents if !agents.empty?
        AirTrafficControl::agents().select{|agent| agent["uuid"] == "3AD70E36-826B-4958-95BF-02E12209C375"}
    end
end


