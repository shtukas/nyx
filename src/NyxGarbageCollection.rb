# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()
        
        puts "NyxGarbageCollection::run()"
        
        NyxPrimaryObjects::objectsEnumerator().each{|object|
            next if NyxPrimaryObjects::nyxNxSets().include?(object["nyxNxSet"])
            puts "removing invalid setid : #{object}"
            NyxObjects::destroy(object)
        }

        Arrows::arrows().each{|arrow|
            b1 = NyxPrimaryObjects::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxPrimaryObjects::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                puts "removing arrow: #{arrow}"
                NyxObjects::destroy(arrow)
            end
        }

        NSDataTypeX::attributes().each{|attribute|
            next if NyxPrimaryObjects::getOrNull(attribute["targetuuid"])
            puts "removing attribute without a target: #{attribute}"
            NyxObjects::destroy(attribute)
        }

        # remove datalines without parent node or asteroid

        NSDataLine::datalines().each{|dataline|
            next if NSDataLine::getDatalineParents(dataline).size > 0
            puts "removing dataline without parents: #{dataline}"
            NyxObjects::destroy(dataline)
        }
        

        # remove datapoints with parent dataline
        NSDataPoint::datapoints().each{|datapoint|
            next if NSDataPoint::getDataPointParents(datapoint).size > 0
            puts "removing datapoint without parents: #{datapoint}"
            NyxObjects::destroy(datapoint)
        }

    end
end
