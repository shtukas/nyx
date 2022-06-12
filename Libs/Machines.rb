
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
end
