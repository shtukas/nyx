#!/usr/bin/ruby

# encoding: UTF-8

CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Archives-Timeline"
CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER = "/Galaxy/DataBank/Catalyst/Stream"

# VirtualScreensManager::init()
# VirtualScreensManager::add(uuid)
# VirtualScreensManager::remove(uuid)
# VirtualScreensManager::test(isPrimaryScreen, uuid)
# VirtualScreensManager::isPrimaryScreen()
# VirtualScreensManager::activatePrimaryScreen()
# VirtualScreensManager::activateSecondaryScreen()
# VirtualScreensManager::lastSecondaryActivationTime()

class VirtualScreensManager
    @@uuids = [] # List the uuids of the secondary screen

    def self.init()
        @@uuids = JSON.parse(KeyValueStore::getOrDefaultValue(nil, "284088e8-90c2-4dab-a1a3-83bbd417b5be", "[]"))
    end

    def self.add(uuid)
        @@uuids << uuid
        KeyValueStore::set(nil, "284088e8-90c2-4dab-a1a3-83bbd417b5be", JSON.generate(@@uuids))
    end

    def self.remove(uuid)
        @@uuids.delete(uuid)
        KeyValueStore::set(nil, "284088e8-90c2-4dab-a1a3-83bbd417b5be", JSON.generate(@@uuids))
    end

    def self.test(isPrimaryScreen, uuid)
        if isPrimaryScreen then
            !@@uuids.include?(uuid)
        else
            @@uuids.include?(uuid)
        end 
    end

    def self.isPrimaryScreen()
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "8dbecdcb-6c37-4a06-840a-8d7c65a0ee40", "[true]"))[0]
    end

    def self.activatePrimaryScreen()
        KeyValueStore::set(nil, "8dbecdcb-6c37-4a06-840a-8d7c65a0ee40", JSON.generate([true]))
    end

    def self.activateSecondaryScreen()
        KeyValueStore::set(nil, "last-secondary-screen-activitation-time:4cf02066-db02-4106-a43e-92ea3f9273ec", Time.new.to_i)        
        KeyValueStore::set(nil, "8dbecdcb-6c37-4a06-840a-8d7c65a0ee40", JSON.generate([false]))
    end
    def self.lastSecondaryActivationTime()
        KeyValueStore::getOrDefaultValue(nil, "last-secondary-screen-activitation-time:4cf02066-db02-4106-a43e-92ea3f9273ec", "0").to_i
    end
end
