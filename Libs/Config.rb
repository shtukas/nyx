
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
end
