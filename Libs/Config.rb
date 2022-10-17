
# encoding: UTF-8

class Config

    # Config::get(key)
    def self.get(key)
        config = JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"))
        config[key]
    end

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToDataCenter()
    def self.pathToDataCenter()
        "#{ENV['HOME']}/Galaxy/DataBank/Stargate-DataCenter"
    end
end