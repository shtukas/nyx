
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToCubes()
    def self.pathToCubes()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data/Cubes"
    end

    # Config::thisInstanceId()
    def self.thisInstanceId()
        object = JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"))
        if object["instanceId"].nil? then
            raise "(error e6d6caec-397f-48d2-9e6d-60d4b8716eb5)"
        end
        object["instanceId"]
    end
end
