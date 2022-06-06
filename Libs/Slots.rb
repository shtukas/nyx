
# encoding: UTF-8

class Slots

    # Slots::getSlots()
    def self.getSlots()
        XCache::getOrDefaultValue("5cd01e58-fcc5-482a-9549-9bc801f9d59b", "")
    end

    # Slots::editSlots()
    def self.editSlots()
        text = XCache::getOrDefaultValue("5cd01e58-fcc5-482a-9549-9bc801f9d59b", "")
        text = CommonUtils::editTextSynchronously(text)
        XCache::set("5cd01e58-fcc5-482a-9549-9bc801f9d59b", text)
    end
end
