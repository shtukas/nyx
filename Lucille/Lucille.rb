
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

    # Lucille::doneLucilleLocation(location)
    def self.doneLucilleLocation(location)
        timeline = Lucille::getLocationTimeline(location)
        if timeline == "[Open Cycles]" then
            puts "You are about to delete an [Open Cycle] item"
            return if !LucilleCore::askQuestionAnswerAsBoolean("Proceed? :")
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

    # Lucille::getUserFriendlyDescriptionForLocation(location)
    def self.getUserFriendlyDescriptionForLocation(location)
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
            Lucille::getUserFriendlyDescriptionForLocation(sublocation)
        else
            File.basename(location)
        end
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
        folder1 = "#{BIN_TIMELINE_FOLDERPATH}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y-%m-%d")}/#{Time.new.strftime("%Y-%m-%d")}"
        folder2 = LucilleCore::indexsubfolderpath(folder1)
        folder3 = "#{folder2}/#{Lucille::timeStringL22()}"
        FileUtils.mkdir(folder3)
        FileUtils.mv(location, folder3)
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

    # LXCluster::startingClusterSize()
    def self.startingClusterSize()
        100
    end

    # LXCluster::selectLocationsForCluster(size)
    # TODO
    def self.selectLocationsForCluster(size)
        Lucille::locations().first(size)
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

    # LXCluster::getClusterOperational()
    # TODO
    def self.getClusterOperational()
        cluster = LXCluster::getClusterFromDisk()

        trace1 = Digest::SHA1.hexdigest(JSON.generate(cluster))

        # Removing location that have disappeared
        cluster["locations"] = cluster["locations"].select{|location| File.exists?(location) }

        # Removing locations that are DoNotShowUntil hidden
        cluster["locations"] = cluster["locations"].select{|location| DoNotShowUntil::isVisible(location) }

        if cluster["locations"].size < 0.5*cluster["startingLocationCount"] then
            cluster = LXCluster::makeNewCluster(LXCluster::selectLocationsForCluster(LXCluster::startingClusterSize()))
            LXCluster::commitClusterToDisk(cluster)
        end

        # We want to remove from cluster["timelinesTimePoints"] the timelines that are no longer 
        # relevant, mostlikely because the corresponding location are gone
        timelines = cluster["locations"].map{|location| Lucille::getLocationTimeline(location) }
        cluster["timelinesTimePoints"] = cluster["timelinesTimePoints"].to_a.select{|pair| timelines.include?(pair[0]) }.to_h

        computeTimelineTimespan = lambda {|cluster, timeline|
            cluster["timelinesTimePoints"][timeline].map{|timepoint| timepoint["timespan"]}.inject(0, :+)
        }

        cluster["computed"] = {}

        cluster["computed"]["timelinesTimespans"] = timelines.map{|timeline| [ timeline , computeTimelineTimespan.call(cluster, timeline) ] }.to_h

        cluster["computed"]["timelineOrdered"] = cluster["computed"]["timelinesTimespans"].to_a.sort{|p1, p2| p1[1]<=>p2[1] }

        lowertimeline = cluster["computed"]["timelineOrdered"][0][0]

        cluster["computed"]["locationsForDisplay"] = cluster["locations"].select{|location| Lucille::getLocationTimeline(location) == lowertimeline }

        trace2 = Digest::SHA1.hexdigest(JSON.generate(cluster))
        if trace1 != trace2 then
            LXCluster::commitClusterToDisk(cluster)
        end
        cluster
    end

    def self.processIncomingLocationTimespan(location, timespan)
        # We get the cluster and add a timepoint to the relevant timeline
    end
end

