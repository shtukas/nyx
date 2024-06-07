
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::stargateFilepath()
    def self.stargateFilepath()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"
    end

    # Config::thisInstanceId()
    def self.thisInstanceId()
        object = JSON.parse(IO.read(Config::stargateFilepath()))
        if object["instanceId"].nil? then
            raise "(error e6d6caec-397f-48d2-9e6d-60d4b8716eb5)"
        end
        object["instanceId"]
    end

    # Config::isPrimaryInstance()
    def self.isPrimaryInstance()
        Config::thisInstanceId() == "Lucille24-pascal"
    end

    # Config::pathToData()
    def self.pathToData()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data"
    end


end
