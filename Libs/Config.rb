
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

    # Config::pathToNightSkyIndex()
    def self.pathToNightSkyIndex()
        "#{Config::pathToGalaxy()}/Nyx/Index"
    end

    # Config::pathToNest()
    def self.pathToNest()
        "#{Config::pathToGalaxy()}/Nyx/Nest"
    end
end
