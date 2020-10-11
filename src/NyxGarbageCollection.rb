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

        Links::links().each{|link|
            b1 = NyxObjects2::getOrNull(link["uuid1"])
            b2 = NyxObjects2::getOrNull(link["uuid2"])
            if !(b1 and b2) then
                puts "removing link: #{link}"
                Links::destroy(link["uuid1"], link["uuid2"])
            end
        }

        Tags::tags().each{|tag|
            targets = Arrows::getTargetsForSource(tag)
            if targets.size == 0 then
                puts "removing tag: #{Tags::toString(tag)}"
                NyxObjects2::destroy(tag)
            end
        }

    end
end
