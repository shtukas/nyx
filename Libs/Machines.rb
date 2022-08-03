
# encoding: UTF-8

class Machines

    # Machines::isLucille20()
    def self.isLucille20()
        ENV["COMPUTERLUCILLENAME"] == "Lucille20"
    end

    # Machines::theOtherInstanceIds()
    def self.theOtherInstanceIds()
        ["Lucille18-pascal", "Lucille20-pascal", "Lucille20-guardian"] - [Config::get("instanceId")]
    end
end
