
# encoding: UTF-8

class Config

    # Config::pathToDataBankStargate()
    def self.pathToDataBankStargate()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate"
    end

    # Config::get(key)
    def self.get(key)
        config = JSON.parse(IO.read("#{Config::pathToDataBankStargate()}/config.json"))
        config[key]
    end

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end
end