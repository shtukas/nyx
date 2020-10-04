
# encoding: UTF-8

class NyxFsck

    # NyxFsck::processDatapoint(datapoint)
    def self.processDatapoint(datapoint)

        puts "fsck datapoint: #{datapoint["uuid"]}"

        if datapoint["type"] == "line" then
            return true
        end

        if datapoint["type"] == "url" then
            return true
        end

        if datapoint["type"] == "NyxFile" then
            filename = datapoint["name"]
            puts "Finding #{filename}"
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location.nil? then
                puts "Failing to find: #{filename}"
                puts JSON.pretty_generate(datapoint)
                puts "[error: 76957559-8830-400d-b4fb-6e00081446a0]"
                return false
            end
            return true
        end

        if datapoint["type"] == "NyxDirectory" then
            nyxDirectoryName = datapoint["name"]
            puts "Finding #{nyxDirectoryName}"
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location.nil? then
                puts "Failing to find: #{nyxDirectoryName}"
                puts JSON.pretty_generate(datapoint)
                puts "[error: f3ba7c41-a0ba-4e16-98d3-46cc083c1453]"
                return false
            end
            return true
        end

        if datapoint["type"] == "NyxFSPoint001" then
            nyxName = datapoint["name"]
            puts "Finding #{nyxName}"
            location = NSNode1638NyxElementLocation::getLocationByAllMeansOrNull(datapoint)
            if location.nil? then
                puts "Failing to find: #{nyxName}"
                puts JSON.pretty_generate(datapoint)
                puts "[error: f3ba7c41-a0ba-4e16-98d3-46cc083c1453]"
                return false
            end
            return true
        end

        puts JSON.pretty_generate(datapoint)
        puts "[error: 10e5efff-380d-4eaa-bf6d-83bf6c1016d5]"
        false
    end

    # NyxFsck::processObject(object, runhash)
    def self.processObject(object, runhash)

        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            # Asteroid
            return true
        end

        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            # Wave
            return true
        end

        if object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" then
            # Datapoint
            NyxFsck::processDatapoint(object)
            return true
        end

        puts JSON.pretty_generate(object)
        puts "[error: eed35593-c378-4715-bbb7-5cbefbcd47ce]"
        false
    end

    # NyxFsck::main(runhash)
    def self.main(runhash)
        NyxObjects2::getAllObjects().each{|object|
            next if KeyValueStore::flagIsTrue(nil, "#{runhash}:#{object["uuid"]}")
            puts "fsck object: #{object["uuid"]}"
            status = NyxFsck::processObject(object, runhash)
            return false if !status
            KeyValueStore::setFlagTrue(nil, "#{runhash}:#{object["uuid"]}")
        }
        true
    end
end
