
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

$NSXPlacementX11 = {}
$NSXPlacementX11[""] = 0

class NSXPlacement

    # NSXPlacement::getValue(objectuuid)
    def self.getValue(objectuuid)
        key = "6d232da2-4bc3-485b-8b78-d9a4d372d589:#{NSXMiscUtils::currentDay()}:#{objectuuid}"
        value = KeyValueStore::getOrNull(nil, key)
        if value then
            value.to_i
        else
            value = $NSXPlacementX11.values.max + 1
            puts "placement: #{objectuuid} @ #{value}"
            $NSXPlacementX11[objectuuid] = value
            KeyValueStore::set(nil, key, value)
            value
        end
    end

    # NSXPlacement::rotate(objectuuid)
    def self.rotate(objectuuid)
        key = "6d232da2-4bc3-485b-8b78-d9a4d372d589:#{NSXMiscUtils::currentDay()}:#{objectuuid}"
        value = $NSXPlacementX11.values.max + 1
        $NSXPlacementX11[objectuuid] = value
        KeyValueStore::set(nil, key, value)
    end
end