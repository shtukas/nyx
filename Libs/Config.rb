
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
end
