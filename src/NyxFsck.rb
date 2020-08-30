
# encoding: UTF-8

class NyxFsck

    # NyxFsck::processDatapoint(datapoint)
    def self.processDatapoint(datapoint)

        puts "fsck datapoint: #{datapoint["uuid"]}"

        if datapoint["type"] == "line" then
            return
        end

        if datapoint["type"] == "url" then
            return
        end

        if datapoint["type"] == "NyxFile" then
            filename = datapoint["name"]
            puts "Finding #{filename}"
            location = NyxGalaxyFinder::uniqueStringToLocationOrNull(filename)
            if location.nil? then
                puts "Failing to find: #{filename}"
                puts JSON.pretty_generate(datapoint)
                raise "[error: 76957559-8830-400d-b4fb-6e00081446a0]"
            end
            return
        end

        if datapoint["type"] == "NyxPod" then
            nyxpodname = datapoint["name"]
            puts "Finding #{nyxpodname}"
            return
            location = NyxGalaxyFinder::uniqueStringToLocationOrNull(nyxpodname)
            if location.nil? then
                puts "Failing to find: #{nyxpodname}"
                puts JSON.pretty_generate(datapoint)
                #raise "[error: f3ba7c41-a0ba-4e16-98d3-46cc083c1453]"
            end
            return
        end

        puts JSON.pretty_generate(datapoint)
        raise "[error: 10e5efff-380d-4eaa-bf6d-83bf6c1016d5]"
    end

    # NyxFsck::processObject(object, runhash)
    def self.processObject(object, runhash)

        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            # Asteroid
            return
        end

        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            # Wave
            return
        end

        if object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" then
            # Datapoint
            NyxFsck::processDatapoint(object)
            return
        end

        if object["nyxNxSet"] == "c18e8093-63d6-4072-8827-14f238975d04" then
            # Node
            return
        end

        if object["nyxNxSet"] == "5c99134b-2b61-4750-8519-49c1d896556f" then
            # NSDataTypeX / attribute
            return
        end

        puts JSON.pretty_generate(object)
        raise "[error: eed35593-c378-4715-bbb7-5cbefbcd47ce]"
    end

    # NyxFsck::main(runhash)
    def self.main(runhash)
        NyxObjectsCore::nyxNxSets().each{|setid|
            NyxObjects2::getSet(setid).each{|object|
                next if KeyValueStore::flagIsTrue(nil, "#{runhash}:#{object["uuid"]}")
                puts "fsck object: #{object["uuid"]}"
                NyxFsck::processObject(object, runhash)
                KeyValueStore::setFlagTrue(nil, "#{runhash}:#{object["uuid"]}")
            }
        }
    end
end
