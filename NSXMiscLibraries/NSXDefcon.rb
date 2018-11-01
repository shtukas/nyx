
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

    # NSXDefcon::computeObjectDefcon(object)
    def self.computeObjectDefcon(object) # integer
        if object["agent-uid"] == "83837e64-554b-4dd0-a478-04386d8010ea" then
            # Baby Nights
            return 2 # Today important
        end
        if ( object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d" ) and ( object["schedule"]["@"]=="sticky" ) then
            # Wave, sticky
            return 1 # Right now
        end
        if ( object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d" ) and ( object["schedule"]["@"]=="every-this-day-of-the-month" ) then
            # Wave, every-this-day-of-the-month
            return 2 # Today important
        end
        if ( object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d" ) and ( object["schedule"]["@"]=="every-this-day-of-the-week" ) then
            # Wave, every-this-day-of-the-month
            return 2 # Today important
        end
        if object["agent-uid"] == "f8a8b8e6-623f-4ce1-b6fe-3bc8b34f7a10" then
            # House
            return 1 # Right now
        end
        if object["agent-uid"] == "283d34dd-c871-4a55-8610-31e7c762fb0d" then
            # LightThreads
            return 2 # Today important
        end
        0
    end

	# NSXDefcon::computeSystemDefcon(objects)
    def self.computeSystemDefcon(objects) # integer
    	5
    end

	# NSXDefcon::defconSelection(objects)
    def self.defconSelection(objects)
        # We start by marking the objects with their defcon number,
        # We compute the system defcon, and
        # We display the objects of the right defcon.
        objects = objects.map{|object| 
            object[":defcon:"] = NSXDefcon::computeObjectDefcon(object) 
            object
        }
    	defcon = NSXDefcon::computeSystemDefcon(objects)
        objects.select{|object| object[":defcon:"] <= defcon } # The inequality allows for the display of objects with defcon 0, which need a code update. 
    end

end

