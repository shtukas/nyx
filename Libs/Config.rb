
# encoding: UTF-8

class Config

    # Config::userHomeDirectory()
    def self.userHomeDirectory()
        ENV['HOME']
    end

    # Config::thisInstanceId()
    def self.thisInstanceId()
        object = JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataBank/Stargate-Config.json"))
        if object["instanceId"].nil? then
            raise "(error e6d6caec-397f-48d2-9e6d-60d4b8716eb5)"
        end
        object["instanceId"]
    end

    # Config::instanceIds()
    def self.instanceIds()
        JSON.parse(IO.read("#{Config::userHomeDirectory()}/Galaxy/DataHub/catalyst/instanceIds.json"))
    end

    # Config::pathToItemsDatabase()
    def self.pathToItemsDatabase()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/Instance-Data-Directories/#{Config::thisInstanceId()}/databases/Items.sqlite3"
    end

    # Config::eventsTimeline()
    def self.eventsTimeline()
        "#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/Instance-Data-Directories/#{Config::thisInstanceId()}/events-timeline"
    end
end
