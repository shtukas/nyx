
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToDesktop()
    def self.pathToDesktop()
        "#{Config::userHomeDirectory()}/Desktop"
    end

    # Config::pathToGalaxy()
    def self.pathToGalaxy()
        "#{Config::userHomeDirectory()}/Galaxy"
    end

    # Config::pathToNyx()
    def self.pathToNyx()
        "#{Config::pathToGalaxy()}/NxData/03-Nyx"
    end

    # Config::configFilepath()
    def self.configFilepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"
    end

    # Config::pathToDataCenter()
    def self.pathToDataCenter()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Stargate-DataCenter"
    end

    # Config::getOrNull(key)
    def self.getOrNull(key)
        config = JSON.parse(IO.read(Config::configFilepath()))
        config[key]
    end

    # Config::getOrFail(key)
    def self.getOrFail(key)
        config = JSON.parse(IO.read(Config::configFilepath()))
        value = config[key]
        if value.nil? then
            raise "could not extract config key: #{key}"
        end
        value
    end

    # Config::set(key, value)
    def self.set(key, value)
        config = JSON.parse(IO.read(Config::configFilepath()))
        config[key] = value
        File.open(Config::configFilepath(), "w"){|f| f.puts(JSON.pretty_generate(config)) }
    end

    # Config::thisInstanceId()
    def self.thisInstanceId()
        Config::getOrFail("instanceId")
    end

    # Config::allInstanceIds()
    def self.allInstanceIds()
        ["Lucille18-pascal", "Lucille20-pascal", "Lucille20-guardian", "Lucille23"]
    end

    # Config::theOtherInstanceIds()
    def self.theOtherInstanceIds()
        Config::allInstanceIds() - [Config::getOrFail("instanceId")]
    end
end
