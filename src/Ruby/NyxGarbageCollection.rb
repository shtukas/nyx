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
                puts "removing arrow: #{arrow}"
                NyxObjects::destroy(arrow)
            end
        }

        Comments::comments().each{|comment|
            next if Arrows::getSourcesForTarget(comment).size > 0
            puts "removing comment: #{comment}"
            NyxObjects::destroy(comment)
        }

    end
end
