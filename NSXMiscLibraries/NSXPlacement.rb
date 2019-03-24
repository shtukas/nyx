
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

$NSXPlacementX11 = JSON.parse(
    KeyValueStore::getOrDefaultValue(nil, "6d232da2-4bc3-485b-8b78-d9b4d372d589:#{Time.now.utc.iso8601[0,10]}", "{}")
)

class NSXPlacement

    # NSXPlacement::getValue(objectuuid)
    def self.getValue(objectuuid)
        value = $NSXPlacementX11[objectuuid]
        if value then
            value
        else
            value = ($NSXPlacementX11.values + [0]).max + 1
            puts "placement: #{objectuuid} @ #{value}"
            $NSXPlacementX11[objectuuid] = value
            KeyValueStore::set(nil, "6d232da2-4bc3-485b-8b78-d9b4d372d589:#{Time.now.utc.iso8601[0,10]}", JSON.generate($NSXPlacementX11))
            value
        end
    end

    # NSXPlacement::rotate(objectuuid)
    def self.rotate(objectuuid)
        value = ($NSXPlacementX11.values + [0]).max + 1
        $NSXPlacementX11[objectuuid] = value
        KeyValueStore::set(nil, "6d232da2-4bc3-485b-8b78-d9b4d372d589:#{Time.now.utc.iso8601[0,10]}", JSON.generate($NSXPlacementX11))
    end

    # NSXPlacement::clean(objectuuids)
    def self.clean(objectuuids)
        ($NSXPlacementX11.keys - objectuuids).each{|objectuuid|
            $NSXPlacementX11.delete(objectuuid)
        }
    end

end