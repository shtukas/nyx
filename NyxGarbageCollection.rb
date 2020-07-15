# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()
        puts "NyxGarbageCollection::run()"
        Arrows::arrows().each{|arrow|
            b1 = NyxPrimaryObjects::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxPrimaryObjects::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                puts "removing: #{arrow}"
                NyxObjects::destroy(arrow["uuid"])
            end
        }
    end
end
