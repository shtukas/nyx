
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::pathToData()
    def self.pathToData()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/Nyx/data"
    end
end
