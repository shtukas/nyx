
# encoding: UTF-8

=begin

This class provides functions to compute heights

[0.90, 1.00[ "75519078" Ultra priority, should have been done already
[0.80, 0.90[ "e58635d6" Sticky waves
[0.75, 8.00[ "97f0669d" ondate(s)
[0.70, 0.75[ "f0047af0" Priority to do now
[0.60, 7.00[ "141de8cf" Items to do today
[0.50, 0.60[ "beca7cc9" Ideally done today, but could be done tomorrow

[0.30, 0.40[ "24e25774" Really nice if done
[0.10, 0.20[ "11d1e8e2" No need to be done but if it's done nobody will mind

=end

class Heights

    # Heights::map()
    def self.map()
        {
            "75519078" => 0.90,
            "e58635d6" => 0.80,
            "97f0669d" => 0.75,
            "f0047af0" => 0.70,
            "141de8cf" => 0.60,
            "beca7cc9" => 0.50,
            "24e25774" => 0.30,
            "11d1e8e2" => 0.10
        }
    end

    # Heights::mapTrace()
    def self.mapTrace()
        Digest::SHA1.hexdigest(Heights::map().to_s)
    end

    # Heights::slotSizeLowerBound()
    def self.slotSizeLowerBound()
        0.05
    end

    # Heights::getShift(uuid)
    def self.getShift(uuid)
        shift = XCache::getOrNull("3ba1bf1a-b7d8-47f5-8357-541674cdda75:#{Heights::mapTrace()}:#{Utils::today()}:#{uuid}")
        if shift then
            return shift.to_f
        else
            shift = Heights::slotSizeLowerBound()*rand
            XCache::set("3ba1bf1a-b7d8-47f5-8357-541674cdda75:#{Heights::mapTrace()}:#{Utils::today()}:#{uuid}", shift)
            return shift
        end
    end

    # Heights::height1(code, uuid)
    def self.height1(code, uuid)
        Heights::map()[code] + Heights::getShift(uuid)
    end

    # Heights::markSequenceOfNS16sWithDecreasingHeights(code, sequence: Array[NS16]) # Array[NS16]
    def self.markSequenceOfNS16sWithDecreasingHeights(code, sequence)
        
        return [] if sequence.empty?

        getPreviouslyRecordedHeightForItemOrNull = lambda {|uuid|
            value = XCache::getOrNull("7fbafe5a-ecd3-497f-ab18-51a3119500bf:#{Heights::mapTrace()}:#{uuid}")
            return nil if value.nil?
            value.to_f
        }

        setHeightForItem = lambda {|uuid, value|
            XCache::set("7fbafe5a-ecd3-497f-ab18-51a3119500bf:#{Heights::mapTrace()}:#{uuid}", value)
        }

        height1 = getPreviouslyRecordedHeightForItemOrNull.call(sequence[0]["uuid"]) || (Heights::map()[code] + Heights::slotSizeLowerBound())
        height0 = Heights::map()[code]
        differential = height1 - height0

        count = sequence.size
        sequence
            .each_with_index.map
            .map{|ns16, indx|
                height = height0 + differential - differential*(indx.to_f/count)
                setHeightForItem.call(ns16["uuid"], height)
                ns16["height"] = height
                ns16
            }
    end

end
