# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()

        ArrowsDatabaseIO::arrows().each{|arrow|
            b1 = NyxObjects2::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxObjects2::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                puts "removing arrow: #{arrow}"
                Arrows::destroy(arrow["sourceuuid"], arrow["targetuuid"])
            end
        }

        Taxonomy::items().each{|item|
            targets = Arrows::getTargetsForSource(item)
            if targets.size == 0 then
                puts "removing taxonomy item: #{Taxonomy::toString(item)}"
                NyxObjects2::destroy(item)
            end
        }

        Tags::tags().each{|tag|
            targets = Arrows::getTargetsForSource(tag)
            if targets.size == 0 then
                puts "removing tag: #{Taxonomy::toString(tag)}"
                NyxObjects2::destroy(tag)
            end
        }

    end
end
