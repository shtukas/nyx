
# encoding: UTF-8

require "/Galaxy/Software/Misc-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

$NSXPlacementX11 = JSON.parse(
    KeyValueStore::getOrDefaultValue(nil, "6d232da2-4bc3-485b-8b78-d9b4d372d599:#{Time.now.utc.iso8601[0,10]}", "{}")
)

class NSXPlacement

    # NSXPlacement::currentDate()
    def self.currentDate()
        Time.now.utc.iso8601[0,10]
    end

    # NSXPlacement::getValue(objectuuid)
    def self.getValue(objectuuid)
        if $NSXPlacementX11[NSXPlacement::currentDate()].nil? then
            $NSXPlacementX11[NSXPlacement::currentDate()] = {}
        end
        value = $NSXPlacementX11[NSXPlacement::currentDate()][objectuuid]
        if value then
            value
        else
            value = ($NSXPlacementX11[NSXPlacement::currentDate()].values + [0]).max + 1
            #puts "placement: #{objectuuid} @ #{value}"
            $NSXPlacementX11[NSXPlacement::currentDate()][objectuuid] = value
            KeyValueStore::set(nil, "6d232da2-4bc3-485b-8b78-d9b4d372d599:#{NSXPlacement::currentDate()}", JSON.generate($NSXPlacementX11))
            value
        end
    end

    # NSXPlacement::relocateToBackOfTheQueue(objectuuid)
    def self.relocateToBackOfTheQueue(objectuuid)
        if $NSXPlacementX11[NSXPlacement::currentDate()].nil? then
            $NSXPlacementX11[NSXPlacement::currentDate()] = {}
        end
        value = ($NSXPlacementX11[NSXPlacement::currentDate()].values + [0]).max + 1
        $NSXPlacementX11[NSXPlacement::currentDate()][objectuuid] = value
        KeyValueStore::set(nil, "6d232da2-4bc3-485b-8b78-d9b4d372d599:#{NSXPlacement::currentDate()}", JSON.generate($NSXPlacementX11))
    end

    # NSXPlacement::clean(objectuuids)
    def self.clean(objectuuids)
        if $NSXPlacementX11[NSXPlacement::currentDate()].nil? then
            $NSXPlacementX11[NSXPlacement::currentDate()] = {}
        end
        ($NSXPlacementX11[NSXPlacement::currentDate()].keys - objectuuids).each{|objectuuid|
            $NSXPlacementX11[NSXPlacement::currentDate()].delete(objectuuid)
        }
    end

end