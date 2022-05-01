
# encoding: UTF-8

=begin

This class provides functions to compute heights

[0.9, 1.0[ "75519078" Ultra priority, should have been done already
[0.8, 0.9[ "f0047af0" Priority to do now.
[0.6, 7.0[ "141de8cf" To do today.
[0.5, 0.6[ "beca7cc9" Ideally done today, but could be done tomorrow

[0.3, 0.4[ "24e25774" Really nice if done.
[0.1, 0.2[ "11d1e8e2" No need to be done but if it's done nobody will mind.

=end

class Heights

    # Heights::map()
    def self.map()
        {
            "75519078" => 0.9,
            "f0047af0" => 0.8,
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

end
