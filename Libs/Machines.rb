
# encoding: UTF-8

class Machines

    # Machines::thisMachine()
    def self.thisMachine()
        ENV["COMPUTERLUCILLENAME"]
    end

    # Machines::theOtherMachine()
    def self.theOtherMachine()
        (ENV["COMPUTERLUCILLENAME"] == "Lucille20") ? "Lucille18" : "Lucille20"
    end

    # Machines::isLucille20()
    def self.isLucille20()
        ENV["COMPUTERLUCILLENAME"] == "Lucille20"
    end

    # Machines::ip_map()
    def self.ip_map()
        {
            "Lucille20" => "192.168.0.3",
            "Lucille18" => "192.168.0.24"
        }
    end

    # Machines::thisMachineIP()
    def self.thisMachineIP()
        Machines::ip_map()[ENV["COMPUTERLUCILLENAME"]]
    end

    # Machines::theOtherMachineIP()
    def self.theOtherMachineIP()
        Machines::ip_map()[Machines::theOtherMachine()]
    end
end
