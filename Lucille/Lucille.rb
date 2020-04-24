
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)

    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/DoNotShowUntil.rb"
#    DoNotShowUntil::setUnixtime(uid, unixtime)
#    DoNotShowUntil::isVisible(uid)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/Mercury.rb"
=begin
    Mercury::postValue(channel, value)
    Mercury::dequeueFirstValueOrNull(channel)

    Mercury::discardFirstElementsToEnforeQueueSize(channel, size)
    Mercury::discardFirstElementsToEnforceTimeHorizon(channel, unixtime)

    Mercury::getQueueSize(channel)
    Mercury::getAllValues(channel)

    Mercury::getFirstValueOrNull(channel)
    Mercury::deleteFirstValue(channel)
=end

# -----------------------------------------------------------------

DATABANK_FOLDER_PATH = "/Users/pascal/Galaxy/DataBank"
CATALYST_FOLDERPATH = "#{DATABANK_FOLDER_PATH}/Catalyst"
BIN_TIMELINE_FOLDERPATH = "#{CATALYST_FOLDERPATH}/Bin-Timeline"

# -----------------------------------------------------------------

class Lucille

    # Lucille::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # -----------------------------
    # IO (1)

    # Lucille::pathToItems()
    def self.pathToItems()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items"
    end

    # Lucille::pathToTimelines()
    def self.pathToTimelines()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Timelines"
    end

    # -----------------------------
    # IO (2)

    # Lucille::applyNextTransformationToContent(content)
    def self.applyNextTransformationToContent(content)

        positionOfFirstNonSpaceCharacter = lambda{|line, size|
            return (size-1) if !line.start_with?(" " * size)
            positionOfFirstNonSpaceCharacter.call(line, size+1)
        }

        lines = content.strip.lines.to_a
        return content if lines.empty?
        slineWithIndex = lines
            .reject{|line| line.strip == "" }
            .each_with_index
            .map{|line, i| [line, i] }
            .reduce(nil) {|selectedLineWithIndex, cursorLineWithIndex|
                if selectedLineWithIndex.nil? then
                    cursorLineWithIndex
                else
                    if (positionOfFirstNonSpaceCharacter.call(selectedLineWithIndex.first, 1) < positionOfFirstNonSpaceCharacter.call(cursorLineWithIndex.first, 1)) and (selectedLineWithIndex[1] == cursorLineWithIndex[1]-1) then
                        cursorLineWithIndex
                    else
                        selectedLineWithIndex
                    end
                end
            }
        sline = slineWithIndex.first
        lines
            .reject{|line| line == sline }
            .join()
            .strip
    end

    # Lucille::garbageCollection()
    def self.garbageCollection()
        Lucille::locations()
            .each{|location|
                next if location[-4, 4] != ".txt"
                content = IO.read(location)
                next if content.nil?
                next if content.strip.size > 0
                FileUtils.rm(location)
            }
    end

    # Lucille::ensureStandardFilenames()
    def self.ensureStandardFilenames()
        Lucille::locations()
            .each{|location|
                if File.basename(location).include?("'") then
                    location2 = "#{File.dirname(location)}/#{File.basename(location).gsub("'", ",")}"
                    FileUtils.mv(location, location2)
                    location = location2
                end
                next if File.basename(location)[0, 3] == "202"
                location2 = "#{File.dirname(location)}/#{Lucille::timeStringL22()} #{File.basename(location)}"
                FileUtils.mv(location, location2)
            }
    end

    # Lucille::destroyLucilleLocationManaged(location)
    def self.destroyLucilleLocationManaged(location)
        timeline = Lucille::getLocationTimeline(location)
        if timeline == "[Open Cycles]" then
            puts "You are about to delete an [Open Cycle] item"
            return if !LucilleCore::askQuestionAnswerAsBoolean("Proceed? ")
        end
        Lucille::moveLocationToCatalystBin(location)
        LucilleCore::removeFileSystemLocation(location)
        location3 = "#{Lucille::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        if File.exists?(location3) then
            LucilleCore::removeFileSystemLocation(location3)
        end
    end

    # -----------------------------
    # Data

    # Lucille::getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(location)
    def self.getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(location)
        locationIsTextFile = lambda {|location| location[-4, 4] == ".txt" }
        locationTextFileHasOneLine = lambda {|location| IO.read(location).strip.lines.to_a.size == 1  }
        locationTextFileStartWithHTTP = lambda {|location| IO.read(location).strip.start_with?("http")  }
        locationDirectoryOnlySubLocationOrNull = lambda {|location|
            filenames = Dir.entries(location)
                            .reject{|filename| filename[0, 1] == "." }
                            .map{|filename| "#{location}/#{filename}" }
            return nil if filenames.size != 1
            filenames[0]
        }
        if File.file?(location) and locationIsTextFile.call(location) and locationTextFileHasOneLine.call(location) and locationTextFileStartWithHTTP.call(location) then
            return IO.read(location).strip
        end
        if File.file?(location) then
            return File.basename(location)
        end
        # Directory
        sublocation = locationDirectoryOnlySubLocationOrNull.call(location)
        if sublocation then
            Lucille::getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(sublocation)
        else
            File.basename(location)
        end
    end

    # Lucille::setDescription(location, description)
    def self.setDescription(location, description)
        KeyValueStore::set(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{location}", description)
    end

    # Lucille::getBestDescription(location)
    def self.getBestDescription(location)
        description = KeyValueStore::getOrNull(nil, "3bbaacf8-2114-4d85-9738-0d4784d3bbb2:#{location}")
        return description if description
        Lucille::getAutomaticallyDeterminedUserFriendlyDescriptionForLocation(location)
    end

    # Lucille::locations()
    def self.locations()
        Dir.entries(Lucille::pathToItems())
            .reject{|filename| filename[0, 1] == "." }
            .sort
            .map{|filename| "#{Lucille::pathToItems()}/#{filename}" }
    end

    # Lucille::timelines()
    def self.timelines()
        Lucille::locations()
            .map{|location| Lucille::getLocationTimeline(location) }
            .uniq
            .sort
    end

    # Lucille::setLocationTimeline(location, timeline)
    def self.setLocationTimeline(location, timeline)
        filepath = "#{Lucille::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        File.open(filepath, "w"){|f| f.puts(timeline) }
    end

    # Lucille::getLocationTimeline(location)
    def self.getLocationTimeline(location)
        filepath = "#{Lucille::pathToTimelines()}/#{File.basename(location)}.timeline.txt"
        return "[Inbox]" if !File.exists?(filepath)
        IO.read(filepath).strip
    end

    # Lucille::getTimelineLocations(timeline)
    def self.getTimelineLocations(timeline)
        Lucille::locations()
            .select{|location| Lucille::getLocationTimeline(location) == timeline }
    end

    # -----------------------------
    # Operations

    # Lucille::openLocation(location)
    def self.openLocation(location)
        openableFileExtensions = [
            ".txt",
            ".jpg",
            ".png",
            ".eml",
            ".webm",
            ".jpeg",
            ".webloc"
        ]

        return if !File.exists?(location)
        if File.directory?(location) then
            system("open '#{location}'")
            return
        end

        if File.file?(location) and location[-4, 4] == ".txt" and IO.read(location).strip.lines.to_a.size == 1 and IO.read(location).strip.start_with?("http") then
            url = IO.read(location).strip
            if ENV["COMPUTERLUCILLENAME"] == "Lucille18" then
                system("open '#{url}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{url}'")
            end
            return
        end

        if File.file?(location) and openableFileExtensions.any?{|extension| location[-extension.size, extension.size] == extension } then
            system("open '#{location}'")
            return
        end
    end

    # Lucille::moveLocationToCatalystBin(location)
    def self.moveLocationToCatalystBin(location)
        return if location.nil?
        return if !File.exists?(location)
        folder1 = "#{BIN_TIMELINE_FOLDERPATH}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{Lucille::timeStringL22()}"
        FileUtils.mkdir(folder3)
        FileUtils.mv(location, folder3)
    end

    # Lucille::transformIntoNyxItem(location)
    def self.transformIntoNyxItem(location)
        return if location.nil?
        puts "Transform as Nyx item: #{location}"
        foldername2 = Lucille::timeStringL22()
        folder2 = "/Users/pascal/Galaxy/Nyx/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m")}/#{foldername2}"
        FileUtils.mkpath(folder2)
        LucilleCore::copyFileSystemLocation(location, folder2)
        system("/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/nyx-make-nyx-permadir-using-this-repository-basename '#{foldername2}'")
        nyxItems = JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Nyx/nyx-permanodes`)
        flag1 = nyxItems
                    .any?{|item| 
                        item["targets"].size == 1 and item["targets"][0]["type"] == "perma-dir-11859659" and item["targets"][0]["foldername"] == foldername2
                    }
        if flag1 then
            puts "Looks like we have confirmation of the creation of that permanode"
            puts "Removing Lucille location"
            LucilleCore::removeFileSystemLocation(location)
        else
            puts "[error] I did not get confirmation that Nyx item was created!"
            LucilleCore::pressEnterToContinue()
        end
    end

    # Lucille::transformLocationFileIntoLocationFolder(location)
    def self.transformLocationFileIntoLocationFolder(location)
        return File.basename(location) if !File.file?(location)
        locationbasename = File.basename(location)
        location2basename = Lucille::timeStringL22()

        location2 = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{location2basename}" # The new receptacle for the file
        FileUtils.mkdir(location2)
        LucilleCore::copyFileSystemLocation(location, location2)

        loop {
            timelinefilepathbefore = "#{Lucille::pathToTimelines()}/#{locationbasename}.timeline.txt"
            break if !File.exists?(timelinefilepathbefore)
            timelinefilepathafter = "#{Lucille::pathToTimelines()}/#{location2basename}.timeline.txt"
            FileUtils.mv(timelinefilepathbefore, timelinefilepathafter)
            break
        }

        loop {
            description = Lucille::getBestDescription(location)
            break if description.nil?
            Lucille::setDescription(location2, description)
            break
        }

        LucilleCore::removeFileSystemLocation(location)

        channel = "0b5b0b54-ea17-40f6-b3f7-d0bfaa641470-lucille-to-ifcs-rebasing"
        message = {
            "old" => locationbasename,
            "new" => location2basename
        }
        Mercury::postValue(channel, message)

        location2basename
    end

    # Lucille::selectLocationOrNull()
    def self.selectLocationOrNull()
        timelineDiveForSelection = lambda{|timeline|
            puts "-> #{timeline}"
            locations = Lucille::getTimelineLocations(timeline)
            LucilleCore::selectEntityFromListOfEntitiesOrNull("locations:", locations, lambda {|location| Lucille::getBestDescription(location) })
        }
        timeline = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline:", Lucille::timelines())
        return nil if timeline.nil?
        timelineDiveForSelection.call(timeline)
    end

end

class LXRunManagement

    # LXRunManagement::getRunUnixtimeOrNull(location)
    def self.getRunUnixtimeOrNull(location)
        value = KeyValueStore::getOrNull(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
        return nil if value.nil?
        value.to_i
    end

    # LXRunManagement::locationIsRunning(location)
    def self.locationIsRunning(location)
        !LXRunManagement::getRunUnixtimeOrNull(location).nil?
    end

    # LXRunManagement::startLocation(location)
    def self.startLocation(location)
        return if LXRunManagement::getRunUnixtimeOrNull(location)
        KeyValueStore::set(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}", Time.new.to_i)
    end

    # LXRunManagement::stopLocation(location) # return timespan or null
    def self.stopLocation(location)
        unixtime = LXRunManagement::getRunUnixtimeOrNull(location)
        return nil if unixtime.nil?
        KeyValueStore::destroy(nil, "50e4fe12-de3d-4def-915b-8924c9195a51:#{location}")
        Time.new.to_i - unixtime
    end
end

=begin

Cluster is a structure that contains a subset of the locations and the time points 
required for the timeline management. 

Cluster {
    "creationUnixtime"      : Integer
    "creatinoDatetime"      : String
    "locations"             : Array[String] # Locations
    "startingLocationCount" : Int
    "timelinesTimePoints"   : Map[Timeline, Array[TimePoint]]
    "computed"              : Object
}

TimePoint {
    "unixtime" : Int
    "timespan" : Float
}

=end

class LXCluster

    # LXCluster::selectLocationsForCluster()
    def self.selectLocationsForCluster()
        Lucille::timelines()
            .reject{|timeline| timeline=="[Inbox]" or timeline=="[Open Cycles]" }
            .map{|timeline|
                Lucille::getTimelineLocations(timeline).first(20)
            }
            .flatten
    end

    # LXCluster::makeNewCluster(locations)
    def self.makeNewCluster(locations)

        dummyTimepoint = lambda {
            {
                "unixtime" => Time.new.to_i,
                "timespan" => 0
            }
        }

        timelinesTimePoints = {}
        locations.each{|location|
            timeline = Lucille::getLocationTimeline(location)
            timelinesTimePoints[timeline] = [ dummyTimepoint.call() ]
        }
        {
            "creationUnixtime"      => Time.new.to_i,
            "creatinoDatetime"      => Time.new.to_s,
            "locations"             => locations,
            "startingLocationCount" => locations.size,
            "timelinesTimePoints"   => timelinesTimePoints,
            "computed"           => {}
        }
    end

    # LXCluster::commitClusterToDisk(cluster)
    def self.commitClusterToDisk(cluster)
        filename = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/cluster.json"
        File.open(filename, "w") {|f| f.puts(JSON.pretty_generate(cluster)) }
    end

    # LXCluster::issueNewCluster()
    def self.issueNewCluster()
        locations = LXCluster::selectLocationsForCluster()
        cluster = LXCluster::makeNewCluster(locations)
        LXCluster::commitClusterToDisk(cluster)
    end

    # LXCluster::getClusterFromDisk()
    def self.getClusterFromDisk()
        JSON.parse(IO.read("/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/cluster.json"))
    end

    # LXCluster::curateOrRespawnCluster()
    def self.curateOrRespawnCluster()
        cluster = LXCluster::getClusterFromDisk()

        trace1 = Digest::SHA1.hexdigest(JSON.generate(cluster))

        # Removing location that have disappeared
        cluster["locations"] = cluster["locations"].select{|location| File.exists?(location) }

        # Removing locations that are DoNotShowUntil hidden
        cluster["locations"] = cluster["locations"].select{|location| DoNotShowUntil::isVisible(location) }

        if cluster["locations"].size < 0.5*cluster["startingLocationCount"] then
            cluster = LXCluster::makeNewCluster(LXCluster::selectLocationsForCluster())
            LXCluster::commitClusterToDisk(cluster)
        end

        # We want to remove from cluster["timelinesTimePoints"] the timelines that are no longer 
        # relevant, mostlikely because the corresponding location are gone
        timelines = cluster["locations"].map{|location| Lucille::getLocationTimeline(location) }

        timelines.each{|timeline|
            if cluster["timelinesTimePoints"][timeline].nil? then
                # This happens when the location was recast and put on a timeline that wasn't originally in the cluster
                cluster["timelinesTimePoints"][timeline] = []
            end
        }

        computeTimelineTimespan = lambda {|cluster, timeline|

            cluster["timelinesTimePoints"][timeline].map{|timepoint| timepoint["timespan"]}.inject(0, :+)
        }

        cluster["computed"] = {}

        cluster["computed"]["timelinesTimespans"] = timelines.map{|timeline| [ timeline , computeTimelineTimespan.call(cluster, timeline) ] }.to_h

        cluster["computed"]["timelineOrdered"] = cluster["computed"]["timelinesTimespans"].to_a.sort{|p1, p2| p1[1]<=>p2[1] }

        cluster["computed"]["locationsForDisplay"] = cluster["computed"]["timelineOrdered"]
                                                        .map{|item| item[0] }
                                                        .map{|timeline|  
                                                            cluster["locations"].select{|location| Lucille::getLocationTimeline(location) == timeline }
                                                        }
                                                        .flatten

        trace2 = Digest::SHA1.hexdigest(JSON.generate(cluster))
        if trace1 != trace2 then
            LXCluster::commitClusterToDisk(cluster)
        end
        cluster
    end

    # LXCluster::processIncomingLocationTimespan(location, timespan)
    def self.processIncomingLocationTimespan(location, timespan)
        timeline = Lucille::getLocationTimeline(location)
        cluster = LXCluster::getClusterFromDisk()
        return if cluster["timelinesTimePoints"][timeline].nil?
        point = {
            "unixtime" => Time.new.to_i,
            "timespan" => timespan
        }
        cluster["timelinesTimePoints"][timeline] << point
        LXCluster::commitClusterToDisk(cluster)
    end
end

class LXUserInterface

    # LXUserInterface::doneLucilleLocation(location)
    def self.doneLucilleLocation(location)
        timespan = LXRunManagement::stopLocation(location)
        if timespan then
            LXCluster::processIncomingLocationTimespan(location, timespan)
        end
        Lucille::destroyLucilleLocationManaged(location)
        LXCluster::curateOrRespawnCluster()
    end

    # LXUserInterface::recastLucilleLocation(location)
    def self.recastLucilleLocation(location)
        timespan = LXRunManagement::stopLocation(location)
        if timespan then
            LXCluster::processIncomingLocationTimespan(location, timespan)
        end
        timeline = nil
        loop {
            timelines = Lucille::timelines().reject{|timeline| timeline == "[Inbox]" }
            t = LucilleCore::selectEntityFromListOfEntitiesOrNull("timeline", timelines)
            if t then
                timeline = t
                break
            end
            t = LucilleCore::askQuestionAnswerAsString("timeline: ")
            if t.size>0 then
                timeline = t
                break
            end
        }
        Lucille::setLocationTimeline(location, timeline)
        LXCluster::curateOrRespawnCluster()
    end

    # LXUserInterface::ifcsLucilleLocation(location)
    def self.ifcsLucilleLocation(location)
        # First we start my migrating the location to timeline [Open Cycles]
        Lucille::setLocationTimeline(location, "[Open Cycles]")
        # Now we need to create a new ifcs item, the only non trivial step if to decide the position
        makeNewIFCSItemPosition = lambda {
            JSON.parse(`/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/InFlightControlSystem/ifcs-items`)
                .sort{|i1, i2| i1["position"] <=> i2["position"]}
                .each{|item|
                    puts "   - (#{"%5.3f" % item["position"]}) #{item["description"]}"
                }
            LucilleCore::askQuestionAnswerAsString("position: ").to_f
        }
        position = makeNewIFCSItemPosition.call()
        uuid = SecureRandom.uuid
        item = {
            "uuid"                    => uuid,
            "lucilleLocationBasename" => File.basename(location),
            "description"             => LucilleCore::askQuestionAnswerAsString("description: "),
            "position"                => position
        }
        File.open("/Users/pascal/Galaxy/DataBank/Catalyst/InFlightControlSystem/items/#{uuid}.json", "w"){|f| f.puts(JSON.pretty_generate(item)) }
    end

    # LXUserInterface::locationDive(location)
    def self.locationDive(location)
        loop {
            system("clear")
            puts "location: #{location}"
            puts "description: #{Lucille::getBestDescription(location)}"
            options = [
                "open",
                "done",
                "set description",
                "export to desktop",
                "recast",
                "transmute into folder",
                "do not show until",
                "merge with other Lucille location",
                ">ifcs",
                ">nyx"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "open" then
                Lucille::openLocation(location)
            end
            if option == "done" then
                LXUserInterface::doneLucilleLocation(location)
                return
            end
            if option == "set description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                Lucille::setDescription(location, description)
            end
            if option == "export to desktop" then
                LucilleCore::copyFileSystemLocation(location, "/Users/pascal/Desktop")
            end
            if option == "recast" then
                LXUserInterface::recastLucilleLocation(location)
            end
            if option == "do not show until" then
                hours = LucilleCore::askQuestionAnswerAsString("Postpone for (in hours): ").to_f
                DoNotShowUntil::setUnixtime(location, Time.new.to_i + hours*3600)
            end
            if option == ">ifcs" then
                LXUserInterface::ifcsLucilleLocation(location)
            end
            if option == "merge with other Lucille location" then
                location2 = Lucille::selectLocationOrNull()
                exit if location2.nil?
                if File.file?(location2) then
                    locationbasename2 = Lucille::transformLocationFileIntoLocationFolder(location2)
                    location2 = "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{locationbasename2}"
                end
                LucilleCore::copyFileSystemLocation(location, location2)
                LucilleCore::removeFileSystemLocation(location)
            end
            if option == ">nyx" then
                Lucille::transformIntoNyxItem(location)
            end
            if option == "transmute into folder" then
                Lucille::transformLocationFileIntoLocationFolder(location)
            end
        }
    end

    # LXUserInterface::timelineDive(timeline)
    def self.timelineDive(timeline)
        puts "-> #{timeline}"
        loop {
            locations = Lucille::getTimelineLocations(timeline)
            location = LucilleCore::selectEntityFromListOfEntitiesOrNull("locations:", locations, lambda {|location| Lucille::getBestDescription(location) })
            break if location.nil?
            LXUserInterface::locationDive(location)
        }
    end

end
