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

    end
end
