
# encoding: UTF-8

class Config

    # Config::pathToDataBankStargate()
    def self.pathToDataBankStargate()
        "/Users/pascal/Galaxy/DataBank/Stargate"
    end

    # Config::get(key)
    def self.get(key)
        config = JSON.parse(IO.read("#{Config::pathToDataBankStargate()}/config.json"))
        config[key]
    end
end