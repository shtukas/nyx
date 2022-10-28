# encoding: UTF-8

class GridFire

    # GridFire::orderStates(states)
    def self.orderStates(states)
        states.sort{|s1, s2| s1["unixtime"] <=> s2["unixtime"] }
    end

    # GridFire::combineStates(states1, states2)
    def self.combineStates(states1, states2)
        states = (states1+states2).reduce([]){|sts, state|
            if sts.any?{|s| s["uuid"] == state["uuid"] } then
                sts
            else
                sts + [state]
            end
        }
        GridFire::orderStates(states)
    end

    # GridFire::objectLocationToExportFolder(location1)
    def self.objectLocationToExportFolder(location1)
        location2 = 
            if File.basename(location1) == "NxGridPointN" then
                "#{File.dirname(location1)}/Contents"
            else
                location1.gsub(".NxGridPointN", "")
            end
        if !File.exists?(location2) then
            puts "GridFire: I am trying to get the export folder for object '#{location1}'"
            puts "GridFire: but I can't find it."
        end
        location2
    end

    # GridFire::getCachedTraceOrNull(objectfilepath, stateuuid)
    def self.getCachedTraceOrNull(objectfilepath, stateuuid)
        XCache::getOrNull("CBF711E1-5052-458A-9AAC-91FE0C3C82B8:#{objectfilepath}:#{stateuuid}")
    end

    # GridFire::setTrace(objectfilepath, stateuuid, trace)
    def self.setTrace(objectfilepath, stateuuid, trace)
        XCache::set("CBF711E1-5052-458A-9AAC-91FE0C3C82B8:#{objectfilepath}:#{stateuuid}", trace)
    end

    # GridFire::pickupFsChanges()
    def self.pickupFsChanges()
        Find.find("#{Config::userHomeDirectory()}/Galaxy/OpenCycles") do |path|
            if path[-12, 12] == "NxGridPointN" then
                location1 =  path
                puts "GridFire: probing #{location1}"
                fsObject = JSON.parse(IO.read(location1))
                uuid = fsObject["uuid"]
                location2 = GridFire::objectLocationToExportFolder(location1)
                #puts "location2: #{location2}"
                currentTrace = CommonUtils::locationTrace(location2)
                #puts "currentTrace: #{currentTrace}"
                cachedTrace = GridFire::getCachedTraceOrNull(location1, fsObject["states"].last["uuid"])
                shouldMakeNewState = (cachedTrace.nil? or (currentTrace != cachedTrace))
                if shouldMakeNewState then
                    puts "GridFire: about to make new state from: #{location2}".green
                    state = GridState::directoryPathToNxDirectoryContentsGridState(location2)
                    #puts JSON.pretty_generate(state)
                    fsObject["states"] << state
                    File.open(location1, "w"){|f| f.puts(JSON.pretty_generate(fsObject)) }
                    GridFire::setTrace(location1, state["uuid"], currentTrace)
                end
            end
        end
    end

    # GridFire::syncOnce()
    def self.syncOnce()
        Find.find("#{Config::userHomeDirectory()}/Galaxy/OpenCycles") do |path|
            if path[-12, 12] == "NxGridPointN" then
                location1 =  path
                puts "GridFire: probing #{location1}"
                fsObject = JSON.parse(IO.read(location1))
                uuid = fsObject["uuid"]
                # The first thing we do is to sync with network
                networkObject = NxGridPointN::getItemOrNull(uuid)
                if networkObject.nil? then
                    puts "GridFire: I could not find the network equivalent of location1: #{location1}"
                    puts "GridFire: Exiting"
                    exit
                end
                combinedStates = GridFire::combineStates(fsObject["states"], networkObject["states"])
                if combinedStates.size > networkObject["states"].size then
                    puts "GridFire: sending updated object to network".green
                    networkObject["states"] = combinedStates
                    NxGridPointN::commitObject(networkObject)
                end
                if combinedStates.size > fsObject["states"].size then
                    puts "GridFire: sending updated object to disk".green
                    if combinedStates.last["type"] != "NxDirectoryContents" then
                        puts "GridFire: The updated last state of object here: #{location1}"
                        puts "GridFire: is not a NxDirectoryContents"
                        puts "GridFire: Exiting"
                        exit
                    end
                    fsObject["states"] = combinedStates
                    File.open(location1, "w"){|f| f.puts(JSON.pretty_generate(fsObject)) }
                    location2 = GridFire::objectLocationToExportFolder(location1)
                    puts "GridFire: exporting the last state to: #{location2}".green
                    state = fsObject["states"].last
                    GridState::exportNxDirectoryContentsRootsAtFolder(state["rootnhashes"], location2)
                    GridFire::setTrace(location1, state["uuid"], CommonUtils::locationTrace(location2))
                end
            end
        end
    end

    # GridFire::run()
    def self.run()
        GridFire::pickupFsChanges()
        GridFire::syncOnce()
        GridFire::syncOnce()
    end
end
