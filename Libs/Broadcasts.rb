
class Broadcasts

    # Makers

    # Broadcasts::makeItemInit(uuid, mikuType)
    def self.makeItemInit(uuid, mikuType)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "ItemInit",
            "payload" => {
                "uuid"     => uuid,
                "mikuType" => mikuType
            }
        }
    end

    # Broadcasts::makeItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.makeItemAttributeUpdate(itemuuid, attname, attvalue)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "ItemAttributeUpdate",
            "payload" => {
                "itemuuid" => itemuuid,
                "attname"  => attname,
                "attvalue" => attvalue
            }
        }
    end

    # Broadcasts::makeItemDestroy(itemuuid)
    def self.makeItemDestroy(itemuuid)
        {
            "uuid"      => SecureRandom.uuid,
            "unixtime"  => Time.new.to_i,
            "eventType" => "ItemDestroy2",
            "payload" => {
                "uuid" => itemuuid,
            }
        }
    end

    # Publishers

    # Broadcasts::publish(event)
    def self.publish(event)
        Config::instanceIds().each{|instanceId|
            next if instanceId == Config::thisInstanceId()
            fragment1 = "#{Config::userHomeDirectory()}/Galaxy/DataHub/nyx/Instance-Data-Directories/#{instanceId}/events-timeline"
            fragment2 = "#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
            folder1 = "#{fragment1}/#{fragment2}"
            if !File.exist?(folder1) then
                FileUtils.mkpath(folder1)
            end
            folder2 = LucilleCore::indexsubfolderpath(folder1, 100)
            filepath1 = "#{folder2}/#{CommonUtils::timeStringL22()}.json"
            File.open(filepath1, "w"){|f| f.puts(JSON.pretty_generate(event)) }
        }
    end

    # Broadcasts::publishItemInit(uuid, mikuType)
    def self.publishItemInit(uuid, mikuType)
        ItemsDatabase::itemInit(uuid, mikuType)
        Broadcasts::publish(Broadcasts::makeItemInit(uuid, mikuType))
    end

    # Broadcasts::publishItemAttributeUpdate(itemuuid, attname, attvalue)
    def self.publishItemAttributeUpdate(itemuuid, attname, attvalue)
        ItemsDatabase::itemAttributeUpdate(itemuuid, attname, attvalue)
        Broadcasts::publish(Broadcasts::makeItemAttributeUpdate(itemuuid, attname, attvalue))
    end

    # Broadcasts::publishItemDestroy(itemuuid)
    def self.publishItemDestroy(itemuuid)
        ItemsDatabase::itemDestroy(itemuuid)
        Broadcasts::publish(Broadcasts::makeItemDestroy(itemuuid))
    end
end