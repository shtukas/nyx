# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run(verbose)
    def self.run(verbose)

        ArrowsDatabaseIO::arrows().each{|arrow|
            b1 = NyxObjects2::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxObjects2::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                if verbose then
                    puts "removing arrow: #{arrow}"
                end
                Arrows::destroy(arrow["sourceuuid"], arrow["targetuuid"])
            end
        }

        NSDataTypeX::attributes().each{|attribute|
            if NyxObjects2::getOrNull(attribute["targetuuid"]).nil? then
                if verbose then
                    puts "removing attribute without a target: #{attribute}"
                end
                NyxObjects2::destroy(attribute)
            end
        }

    end
end
