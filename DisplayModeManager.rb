
# encoding: UTF-8

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "json"
require "find"

# FKVStore::set(key, value)
# FKVStore::getOrNull(key): value
# FKVStore::getOrDefaultValue(key, defaultValue): value
# FKVStore::delete(key)

# ----------------------------------------------------------------------

# DisplayModes: ["default"], ["list", <listuuid>]

class DisplayModeManager

    # DisplayModeManager::getDisplayMode()
    def self.getDisplayMode()
        JSON.parse(FKVStore::getOrDefaultValue("1ce5e7a5-a509-4ad2-93ad-33647940dcbe", '["default"]'))
    end

    # DisplayModeManager::putDisplayMode(displaymode)
    def self.putDisplayMode(displaymode)
        FKVStore::set("1ce5e7a5-a509-4ad2-93ad-33647940dcbe", JSON.generate(displaymode))
    end

end


