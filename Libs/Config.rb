
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToGalaxy()
    def self.pathToGalaxy()
        "#{Config::userHomeDirectory()}/Galaxy"
    end

    # Config::instanceId()
    def self.instanceId()
        filepath = "#{Config::pathToGalaxy()}/DataBank/Stargate-Config.json"
        if !File.exist?(filepath) then
            raise "I can't find the config file: #{filepath}"
        end
        JSON.parse(IO.read(filepath))["instanceId"]
    end

    # Config::pathToTheLibrarianDatablobsPartial()
    def self.pathToTheLibrarianDatablobsPartial()
        "#{Config::pathToGalaxy()}/DataHub/Nyx/data/TheLibrarian/datablobs-partial-v001"
    end

    # Config::pathToTheLibrarianObjects()
    def self.pathToTheLibrarianObjects()
        "#{Config::pathToGalaxy()}/DataHub/Nyx/data/TheLibrarian/objects-v001"
    end
end
