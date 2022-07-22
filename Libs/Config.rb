
# encoding: UTF-8

class Config

    # Config::pathToLocalDataBankStargate()
    def self.pathToLocalDataBankStargate()
        "#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate"
    end

    # Config::get(key)
    def self.get(key)
        config = JSON.parse(IO.read("#{Config::pathToLocalDataBankStargate()}/config.json"))
        config[key]
    end

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end
end