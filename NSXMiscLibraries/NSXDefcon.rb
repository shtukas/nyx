
# encoding: UTF-8

=begin

Defcon Codes System:
    1 : Right now
    2 : Today important
    3 : Today non important
    4 : Best efforts
    5 : Stream

Defcon Codes Objects:
    # All the system codes together with
    0 : Unattributed # When this comes up, there is a code update invite to classify the object

=end

class NSXDefcon

    # NSXDefcon::defconCodeToDescription(code)
    def self.defconCodeToDescription(code)
        mapping = {
            "0" => "Warning: Catalyst Object without a computed defcon code",
            "1" => "Right now",
            "2" => "Today important",
            "3" => "Today non important",
            "4" => "Best efforts",
            "5" => "Stream"
        }
        mapping[code.to_s]
    end

    # NSXDefcon::computeObjectDefcon(object)
    def self.computeObjectDefcon(object) # [integer, string]
        if object["agent-uid"] == "83837e64-554b-4dd0-a478-04386d8010ea" then
            # Baby Nights
            return [2, "37b36b3c"] # Today important
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="new") and object["announce"].include?("[new] http") then
            # Wave, new, http # mostly former stream
            return [3, "201b26f8"] # 3 : Today non important
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="new") and object["announce"].include?("new") then
            # Wave, new
            return [1, "e7a13247"] # 1 : Right now
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="new") then
            # Wave, new
            return [4, "238f36ac"] # Best efforts
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="sticky") then
            # Wave, sticky
            return [1, "97f018a8"] # Right now
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="every-this-day-of-the-month") then
            # Wave, every-this-day-of-the-month
            return [2, "93d81c5b"] # Today important
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="every-this-day-of-the-week") then
            # Wave, every-this-day-of-the-month
            return [2, "0e7e5620"] # Today important
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="every-n-hours") then
            # Wave, every-n-hours
            return [3, "26ea35fe"] # 3 : Today non important
        end
        if (object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d") and (object["schedule"]["@"]=="every-n-days") then
            # Wave, every-n-days
            return [3, "2a86372c"] # 3 : Today non important
        end
        if object["agent-uid"] == "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10" then
            # House
            return [1, "34fe2651"] # Right now
        end
        if object["agent-uid"] == "201cac75-9ecc-4cac-8ca1-2643e962a6c6" then
            # LightThreads
            return [2, "a70b49e9"] # Today important
        end
        if object["agent-uid"] == "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58" then
            # Ninja
            return [4, "bb3fc208"] # 4 : Best efforts
        end
        0
    end

	# NSXDefcon::computeSystemDefcon(objects)
    def self.computeSystemDefcon(objects) # integer
    	objects.map{|object| NSXDefcon::computeObjectDefcon(object)[0] }.min
    end

	# NSXDefcon::defconSelection(objects)
    def self.defconSelection(objects)
        # We start by marking the objects with their defcon number,
        # We compute the system defcon, and
        # We display the objects of the right defcon.
        objects = objects.map{|object|
            if object["metric"] < 1 then
                defcon, defconOrigin = NSXDefcon::computeObjectDefcon(object)
                object[":defcon:"] = defcon
                object[":defcon-origin:"] = defconOrigin
            else
                object[":defcon:"] = 1
                object[":defcon-origin:"] = "bc838ec5-2efc-40fd-8bdf-b40d5945ab28"
            end
            object
        }
    	systemDefcon = NSXDefcon::computeSystemDefcon(objects)
        [systemDefcon, objects.select{|object| object[":defcon:"] <= systemDefcon }] # The inequality allows for the display of objects with defcon 0, which need a code update. 
    end

end

