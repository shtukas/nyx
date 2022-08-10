
# encoding: UTF-8

class Machines

    # Machines::isLucille20()
    def self.isLucille20()
        ENV["COMPUTERLUCILLENAME"] == "Lucille20"
    end

    # Machines::theOtherInstanceIds()
    def self.theOtherInstanceIds()
        SharedConfig::get("allInstanceIds") - [Config::get("instanceId")]
    end
end
