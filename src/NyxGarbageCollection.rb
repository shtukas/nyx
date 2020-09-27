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

        Vectors::vectors().each{|vector|
            vectorTargets = Arrows::getTargetsForSource(vector)
            if vectorTargets.size == 0 then
                puts "removing vector: #{Vectors::toString(vector)}"
                NyxObjects2::destroy(vector)
            end
        }

    end
end
