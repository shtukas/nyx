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

        NSDataTypeX::attributes().each{|attribute|
            if NyxObjects2::getOrNull(attribute["targetuuid"]).nil? then
                puts "removing attribute without a target: #{attribute}"
                NyxObjects2::destroy(attribute)
            end
        }

    end
end
