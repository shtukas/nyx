
# encoding: UTF-8

class NyxFsck

    # NyxFsck::processDatapoint(datapoint)
    def self.processDatapoint(datapoint)

        puts "fsck datapoint: #{datapoint["uuid"]}"

        if datapoint["type"] == "aion-point" then
            nhash = datapoint["namedhash"]
            puts "Fsck aion-point / namedhash: #{nhash}"
            status = LibrarianElizabeth.new().datablobCheck(nhash)
            if !status then
                puts "Failing to fsck aion-point / namedhash: #{nhash}"
                raise "[error: 9bda75e4-b449-4547-9ae5-82fa9573fd5b]"
            end
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
            location = NyxGalaxyFinder::uniqueStringToLocationOrNull(nyxpodname)
            if location.nil? then
                puts "Failing to find: #{nyxpodname}"
                puts JSON.pretty_generate(datapoint)
                raise "[error: f3ba7c41-a0ba-4e16-98d3-46cc083c1453]"
            end
            return
        end

        if datapoint["type"] == "line" then
            return
        end

        if datapoint["type"] == "text" then
            namedhash = datapoint["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            if text.nil? then
                raise "[error: f206f1a5-598d-41d1-898b-f161487b7b28]"
            end
            return
        end

        if datapoint["type"] == "A02CB78E-F6D0-4EAC-9787-B7DC3BCA86C1" then
            namedhash = datapoint["namedhash"]
            data = NyxBlobs::getBlobOrNull(namedhash)
            if data.nil? then
                raise "[error: e3cf6f0a-8cac-4845-a030-83f731c9088d]"
            end
            return
        end

        puts JSON.pretty_generate(datapoint)
        raise "[error: 10e5efff-380d-4eaa-bf6d-83bf6c1016d5]"
    end

    # NyxFsck::processObject(object)
    def self.processObject(object)

        if object["nyxNxSet"] == "b66318f4-2662-4621-a991-a6b966fb4398" then
            # Asteroid
            return
        end

        if object["nyxNxSet"] == "d319513e-1582-4c78-a4c4-bf3d72fb5b2d" then
            # NSDataLine

            return if Arrows::getSourcesForTarget(object).any?{|source| GenericObjectInterface::isAsteroid(source) }

            Arrows::getTargetsForSource(object).each{|target|
                if target["nyxNxSet"] != "0f555c97-3843-4dfe-80c8-714d837eba69" then
                    puts JSON.pretty_generate(object)
                    puts JSON.pretty_generate(target)
                    raise "[error: 17018fa0-fbc8-44f0-ab1f-4c20c86f3980]"
                end
                next if KeyValueStore::flagIsTrue(nil, "270c3b35-1107-43e2-beb1-478df699089f:#{target["uuid"]}:#{Miscellaneous::today()}")
                NyxFsck::processDatapoint(target)
                KeyValueStore::setFlagTrue(nil, "270c3b35-1107-43e2-beb1-478df699089f:#{target["uuid"]}:#{Miscellaneous::today()}")
            }
            return
        end

        if object["nyxNxSet"] == "7deb0315-98b5-4e4d-9ad2-d83c2f62e6d4" then
            # Wave
            return
        end

        if object["nyxNxSet"] == "0f555c97-3843-4dfe-80c8-714d837eba69" then
            # Datapoint
            # We do not Fsck datapoints directly, only those targetted by Datalines
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

    # NyxFsck::main()
    def self.main()
        NyxObjectsCore::nyxNxSets().each{|setid|
            NyxObjects2::getSet(setid).each{|object|
                next if KeyValueStore::flagIsTrue(nil, "88bfc431-aae9-474b-8acf-356200d36cda:#{object["uuid"]}:#{Miscellaneous::today()}")
                puts "fsck object: #{object["uuid"]}"
                NyxFsck::processObject(object)
                KeyValueStore::setFlagTrue(nil, "88bfc431-aae9-474b-8acf-356200d36cda:#{object["uuid"]}:#{Miscellaneous::today()}")
            }
        }
    end
end
