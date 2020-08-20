# encoding: UTF-8

class NyxGarbageCollection

    # NyxGarbageCollection::run()
    def self.run()
        
        puts "NyxGarbageCollection::run()"

        exit

        ArrowsDatabaseIO::arrows().each{|arrow|
            b1 = NyxObjects2::getOrNull(arrow["sourceuuid"]).nil?
            b2 = NyxObjects2::getOrNull(arrow["targetuuid"]).nil?
            isNotConnecting = (b1 or b2)
            if isNotConnecting then
                puts "removing arrow: #{arrow}"
                $ArrowsInMemory099be9e4.destroy(arrow["sourceuuid"], arrow["targetuuid"])
            end
        }

        return

        NSDataTypeX::attributes().each{|attribute|
            next if NyxObjects2::getOrNull(attribute["targetuuid"])
            puts "removing attribute without a target: #{attribute}"
            NyxObjects2::destroy(attribute)
        }

        # remove datalines without parent: node or asteroid

        NSDataLine::datalines().each{|dataline|
            next if NSDataLine::getDatalineParents(dataline).size > 0
            puts "removing dataline without parents: #{dataline}"
            NyxObjects2::destroy(dataline)
        }
        

        # remove datapoints with parent dataline
        NSDataPoint::datapoints().each{|datapoint|
            next if NSDataPoint::getDataPointParents(datapoint).size > 0
            puts "removing datapoint without parents: #{datapoint}"
            NyxObjects2::destroy(datapoint)
        }

    end
end
