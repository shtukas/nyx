
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

    # Config::pathToNyxData()
    def self.pathToNyxData()
        "#{Config::pathToGalaxy()}/DataHub/Nyx/data"
    end

    # Config::instanceId()
    def self.instanceId()
        filepath = "#{Config::pathToGalaxy()}/DataBank/Stargate-Config.json"
        if !File.exist?(filepath) then
            raise "I can't find the config file: #{filepath}"
        end
        JSON.parse(IO.read(filepath))["instanceId"]
    end
end
