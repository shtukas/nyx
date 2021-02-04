# encoding: UTF-8

class TodoGarbageCollection

    # TodoGarbageCollection::run()
    def self.run()

        TodoArrows::arrows().each{|arrow|
            b1 = TodoCoreData::getOrNull(arrow["sourceuuid"])
            b2 = TodoCoreData::getOrNull(arrow["targetuuid"])
            if !(b1 and b2) then
                puts "removing arrow: #{arrow}"
                TodoArrows::destroy(arrow["sourceuuid"], arrow["targetuuid"])
            end
        }
    end
end
