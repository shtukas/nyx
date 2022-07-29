
# encoding: UTF-8

class Machines

    # Machines::isLucille20()
    def self.isLucille20()
        ENV["COMPUTERLUCILLENAME"] == "Lucille20"
    end

    # Machines::foldernamesForStargateDrop()
    def self.foldernamesForStargateDrop()
        ["Lucille18-pascal", "Lucille20-pascal", "Lucille20-guardian"] - [Config::get("instanceId")]
    end
end
