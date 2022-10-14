
# encoding: UTF-8

class Machines

    # Machines::isLucille20()
    def self.isLucille20()
        ENV["COMPUTERLUCILLENAME"] == "Lucille20"
    end

    # Machines::theOtherInstanceIds()
    def self.theOtherInstanceIds()
        instanceIds = Dir.entries("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-DataCenter/Instance-Databases")
                        .select{|filename| filename[0, 1] != "." }
        instanceIds - [Config::get("instanceId")]
    end
end
