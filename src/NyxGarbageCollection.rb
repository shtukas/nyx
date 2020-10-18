# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()

        ArrowsDatabaseIO::arrows().each{|arrow|
            b1 = NyxObjects2::getOrNull(arrow["sourceuuid"])
            b2 = NyxObjects2::getOrNull(arrow["targetuuid"])
            if !(b1 and b2) then
                puts "removing arrow: #{arrow}"
                Arrows::destroy(arrow["sourceuuid"], arrow["targetuuid"])
            end
        }
    end
end
