
# encoding: UTF-8

=begin

This class provides functions to compute heights

[0.9, 1.0[ "75519078" Ultra priority, should have been done already
[0.8, 0.9[ "e58635d6" Sticky waves
[0.7, 0.8[ "f0047af0" Priority to do now
[0.6, 7.0[ "141de8cf" To do today
[0.5, 0.6[ "beca7cc9" Ideally done today, but could be done tomorrow

[0.3, 0.4[ "24e25774" Really nice if done
[0.1, 0.2[ "11d1e8e2" No need to be done but if it's done nobody will mind

=end

class Heights

    # Heights::map()
    def self.map()
        {
            "75519078" => 0.9,
            "e58635d6" => 0.8,
            "f0047af0" => 0.7,
            "141de8cf" => 0.6,
            "beca7cc9" => 0.5,
            "24e25774" => 0.3,
            "11d1e8e2" => 0.1
        }
    end

    # Heights::getShift(uuid)
    def self.getShift(uuid)
        shift = XCache::getOrNull("3ba1bf1a-b7d8-47f5-8357-541674cdda75:#{Utils::today()}:#{uuid}")
        if shift then
            return shift.to_f
        else
            shift = 0.1*rand
            XCache::set("3ba1bf1a-b7d8-47f5-8357-541674cdda75:#{Utils::today()}:#{uuid}", shift)
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
            value = XCache::getOrNull("7fbafe5a-ecd3-497f-ab18-51a3119500bf:#{uuid}")
            return nil if value.nil?
            value.to_f
        }

        setHeightForItem = lambda {|uuid, value|
            XCache::set("7fbafe5a-ecd3-497f-ab18-51a3119500bf:#{uuid}", value)
        }

        height1 = getPreviouslyRecordedHeightForItemOrNull.call(sequence[0]["uuid"]) || (Heights::map()[code] + 0.08)
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
