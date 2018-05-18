#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"

# ----------------------------------------------------------------

CATALYST_COMMON_DATA_FOLDERPATH = "/Galaxy/DataBank/Catalyst"
CATALYST_COMMON_CONFIG_FILEPATH = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Config.json"
CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Bin-Timeline"
CATALYST_COMMON_XCACHE_REPOSITORY = "#{CATALYST_COMMON_DATA_FOLDERPATH}/XCACHE"
CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Agents-Data/Stream"
CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER = "#{CATALYST_COMMON_DATA_FOLDERPATH}/Agents-Data/Open-Projects"
CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE = "/Galaxy/DataBank/Catalyst/Events-Timeline"
CATALYST_COMMON_PATH_TO_EVENTS_BUFFER_IN = "/Galaxy/DataBank/Catalyst/Events-Buffer-In"

# ----------------------------------------------------------------

$flock = {}
$flock["objects"] = []
$flock["do-not-show-until-datetime-distribution"] = {}
$flock["kvstore"] = {}

# ----------------------------------------------------------------

# Config::get(keyname)

class Config
    def self.getConfig()
        JSON.parse(IO.read(CATALYST_COMMON_CONFIG_FILEPATH))
    end
    def self.get(keyname)
        self.getConfig()[keyname]
    end
end

# Jupiter::isPrimaryComputer()
# Jupiter::currentHour()
# Jupiter::currentDay()
# Jupiter::simplifyURLCarryingString(string)
# Jupiter::traceToRealInUnitInterval(trace)
# Jupiter::traceToMetricShift(trace)
# Jupiter::realNumbersToZeroOne(x, origin, unit)
# Jupiter::codeToDatetimeOrNull(code)

class Jupiter

    def self.isPrimaryComputer()
        ENV["COMPUTERLUCILLENAME"]==Config::get("PrimaryComputerName")
    end

    def self.currentHour()
        Time.new.to_s[0,13]
    end

    def self.currentDay()
        Time.new.to_s[0,10]
    end

    def self.simplifyURLCarryingString(string)
        return string if /http/.match(string).nil?
        [/^\{\s\d*\s\}/, /^\[\]/, /^line:/, /^todo:/, /^url:/, /^\[\s*\d*\s*\]/]
            .each{|regex|
                if ( m = regex.match(string) ) then
                    string = string[m.to_s.size, string.size].strip
                    return Jupiter::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.001*Jupiter::traceToRealInUnitInterval(trace)
    end

    def self.realNumbersToZeroOne(x, origin, unit)
        alpha =
            if x >= origin then
                2-Math.exp(-(x-origin).to_f/unit)
            else
                Math.exp((x-origin).to_f/unit)
            end
        alpha.to_f/2
    end

    def self.codeToDatetimeOrNull(code)
        localsuffix = Time.new.to_s[-5,5]
        if code[0,1]=='+' then
            code = code[1,999]
            if code.index('@') then
                # The first part is an integer and the second HH:MM
                part1 = code[0,code.index('@')]
                part2 = code[code.index('@')+1,999]
                "#{( DateTime.now + part1.to_i ).to_date.to_s} #{part2}:00 #{localsuffix}"
            else
                if code.include?('days') or code.include?('day') then
                    if code.include?('days') then
                        # The entire string is to be interpreted as a number of days from now
                        "#{( DateTime.now + code[0,code.size-4].to_f ).to_time.to_s}"
                    else
                        # The entire string is to be interpreted as a number of days from now
                        "#{( DateTime.now + code[0,code.size-3].to_f ).to_time.to_s}"
                    end

                elsif code.include?('hours') or code.include?('hour') then
                    if code.include?('hours') then
                        ( Time.new + code[0,code.size-5].to_f*3600 ).to_s
                    else
                        ( Time.new + code[0,code.size-4].to_f*3600 ).to_s
                    end
                else
                    nil
                end
            end
        else
            # Here we expect "YYYY-MM-DD" or "YYYY-MM-DD@HH:MM"
            if code.index('@') then
                part1 = code[0,10]
                part2 = code[11,999]
                "#{part1} #{part2}:00 #{localsuffix}"
            else
                part1 = code[0,10]
                part2 = code[11,999]
                "#{part1} 00:00:00 #{localsuffix}"
            end
        end
    end
end

# EventsMaker::destroyCatalystObject(uuid)
# EventsMaker::catalystObject(object)
# EventsMaker::doNotShowUntilDateTime(uuid, datetime)
# EventsMaker::fKeyValueStoreSet(key, value)

class EventsMaker
    def self.destroyCatalystObject(uuid)
        {
            "event-type"  => "Catalyst:Destroy-Catalyst-Object:1",
            "object-uuid" => uuid
        }
    end

    def self.catalystObject(object)
        {
            "event-type" => "Catalyst:Catalyst-Object:1",
            "object"     => object
        }
    end

    def self.doNotShowUntilDateTime(uuid, datetime)
        {
            "event-type"  => "Catalyst:Metadata:DoNotShowUntilDateTime:1",
            "object-uuid" => uuid,
            "datetime"    => datetime
        }
    end

    def self.fKeyValueStoreSet(key, value)
        {
            "event-type" => "Flock:KeyValueStore:Set:1",
            "key"        => key,
            "value"      => value
        }
    end
end

# EventsManager::pathToActiveEventsIndexFolder()
# EventsManager::commitEventToTimeline(event)
# EventsManager::eventsEnumerator()

class EventsManager
    def self.pathToActiveEventsIndexFolder()
        folder1 = "#{CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE}/#{Time.new.strftime("%Y")}/#{Time.new.strftime("%Y%m")}/#{Time.new.strftime("%Y%m%d")}/#{Time.new.strftime("%Y%m%d-%H")}"
        FileUtils.mkpath folder1 if !File.exists?(folder1)
        LucilleCore::indexsubfolderpath(folder1)
    end

    def self.commitEventToTimeline(event)
        folderpath = EventsManager::pathToActiveEventsIndexFolder()
        filepath = "#{folderpath}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath, "w"){ |f| f.write(JSON.pretty_generate(event)) }
    end

    def self.commitEventToBufferIn(event) # To be read only by Lucille18
        filepath = "#{CATALYST_COMMON_PATH_TO_EVENTS_BUFFER_IN}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath, "w"){ |f| f.write(JSON.pretty_generate(event)) }
    end

    def self.eventsEnumerator()
        Enumerator.new do |events|
            Find.find(CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE) do |path|
                next if !File.file?(path)
                next if File.basename(path)[-5,5] != '.json'
                events << JSON.parse(IO.read(path))
            end
        end
    end
end

# FlockTransformations::removeObjectIdentifiedByUUID(uuid)
# FlockTransformations::removeObjectsFromAgent(agentuuid)
# FlockTransformations::addOrUpdateObject(object)
# FlockTransformations::addOrUpdateObjects(objects)

class FlockTransformations
    def self.removeObjectIdentifiedByUUID(uuid)
        $flock["objects"].reject!{|o| o["uuid"]==uuid }
    end

    def self.removeObjectsFromAgent(agentuuid)
        $flock["objects"].reject!{|o| o["agent-uid"]==agentuuid }
    end

    def self.addOrUpdateObject(object)
        FlockTransformations::removeObjectIdentifiedByUUID(object["uuid"])
        $flock["objects"] << object
    end

    def self.addOrUpdateObjects(objects)
        objects.each{|object|
            FlockTransformations::addOrUpdateObject(object)
        }
    end    
end

# FKVStore::getOrNull(key): value
# FKVStore::getOrDefaultValue(key, defaultValue): value
# FKVStore::set(key, value)

class FKVStore
    def self.getOrNull(key)
        value = $flock["kvstore"][key]
        return value if value
        value = KeyValueStore::getOrNull(CATALYST_COMMON_XCACHE_REPOSITORY, key)
        if value then
            $flock["kvstore"][key] = value
            EventsManager::commitEventToTimeline(EventsMaker::fKeyValueStoreSet(key, value))
        end
        value
    end

    def self.getOrDefaultValue(key, defaultValue)
        value = FKVStore::getOrNull(key)
        if value.nil? then
            value = defaultValue
        end
        value
    end

    def self.set(key, value)
        $flock["kvstore"][key] = value
        EventsManager::commitEventToTimeline(EventsMaker::fKeyValueStoreSet(key, value))
    end
end

# RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
# RequirementsOperator::setUnsatisfiedRequirement(requirement)
# RequirementsOperator::setSatisfifiedRequirement(requirement)
# RequirementsOperator::requirementIsCurrentlySatisfied(requirement)

# RequirementsOperator::getObjectRequirements(uuid)
# RequirementsOperator::setObjectRequirements(uuid, requirements)
# RequirementsOperator::addRequirementToObject(uuid,requirement)
# RequirementsOperator::removeRequirementFromObject(uuid,requirement)
# RequirementsOperator::objectMeetsRequirements(uuid)

# RequirementsOperator::getAllRequirements()
# RequirementsOperator::transform()

class RequirementsOperator

    def self.getCurrentlyUnsatisfiedRequirements()
        JSON.parse(FKVStore::getOrDefaultValue("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", "[]"))
    end

    def self.setUnsatisfiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = (rs + [ requirement ]).uniq
        FKVStore::set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.setSatisfifiedRequirement(requirement)
        rs = RequirementsOperator::getCurrentlyUnsatisfiedRequirements()
        rs = rs.reject{|r| r==requirement }
        FKVStore::set("Currently-Unsatisfied-Requirements-7f8bba56-6755-401c-a1d2-490c0176337e", JSON.generate(rs))
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        !RequirementsOperator::getCurrentlyUnsatisfiedRequirements().include?(requirement)
    end

    # objects

    def self.getObjectRequirements(uuid)
        JSON.parse(FKVStore::getOrDefaultValue("Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", "[]"))
    end

    def self.setObjectRequirements(uuid, requirements)
        FKVStore::set("Object-Requirements-List-6acb38bd-3c4a-4265-a920-2c89154125ce:#{uuid}", JSON.generate(requirements))
    end

    def self.addRequirementToObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid) + [requirement]).uniq)
    end

    def self.removeRequirementFromObject(uuid,requirement)
        RequirementsOperator::setObjectRequirements(uuid, (RequirementsOperator::getObjectRequirements(uuid).reject{|r| r==requirement }))
    end

    def self.objectMeetsRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.getAllRequirements()
        $flock["objects"].map{|object| RequirementsOperator::getObjectRequirements(object["uuid"]) }.flatten.uniq
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.transform()
        $flock["objects"] = $flock["objects"].map{|object|
            if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) then
                object["metric"] = 0
            end
            object
        }
    end
end

# TodayOrNotToday::notToday(uuid)
# TodayOrNotToday::todayOk(uuid)
# TodayOrNotToday::transform()

class TodayOrNotToday
    def self.notToday(uuid)
        FKVStore::set("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{Jupiter::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        FKVStore::getOrNull("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{Jupiter::currentDay()}:#{uuid}").nil?
    end
    def self.transform()
        $flock["objects"] = $flock["objects"].map{|object|
            if !TodayOrNotToday::todayOk(object["uuid"]) then
                object["metric"] = 0
            end
            object
        }
    end
end

# FolderProbe::nonDotFilespathsAtFolder(folderpath)
# FolderProbe::folderpath2metadata(folderpath)
    #    {
    #        "target-type" => "folder"
    #        "target-location" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "openable-file"
    #        "target-location" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "line",
    #        "text" => line
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "url",
    #        "url" =>
    #        "announce" =>
    #    }
    #    {
    #        "target-type" => "virtually-empty-wave-folder",
    #        "announce" =>
    #    }

# FolderProbe::openActionOnMetadata(metadata)

class FolderProbe
    def self.nonDotFilespathsAtFolder(folderpath)
        Dir.entries(folderpath)
            .select{|filename| filename[0,1]!="." }
            .map{|filename| "#{folderpath}/#{filename}" }
    end

    def self.folderpath2metadata(folderpath)

        metadata = {}

        # --------------------------------------------------------------------
        # Trying to read a description file

        getDescriptionFilepathMaybe = lambda{|folderpath|
            filepaths = FolderProbe::nonDotFilespathsAtFolder(folderpath)
            if filepaths.any?{|filepath| File.basename(filepath).include?("description.txt") } then
                filepaths.select{|filepath| File.basename(filepath).include?("description.txt") }.first
            else
                nil
            end
        }

        getDescriptionFromDescriptionFileMaybe = lambda{|folderpath|
            filepathOpt = getDescriptionFilepathMaybe.call(folderpath)
            if filepathOpt then
                IO.read(filepathOpt).strip
            else
                nil
            end
        }

        descriptionOpt = getDescriptionFromDescriptionFileMaybe.call(folderpath)
        if descriptionOpt then
            metadata["announce"] = descriptionOpt
            if descriptionOpt.start_with?("http") then
                metadata["target-type"] = "url"
                metadata["url"] = descriptionOpt
                return metadata
            end
        end

        # --------------------------------------------------------------------
        #

        files = FolderProbe::nonDotFilespathsAtFolder(folderpath)
                .select{|filepath| !File.basename(filepath).start_with?('wave') }
                .select{|filepath| !File.basename(filepath).start_with?('catalyst') }

        fileIsOpenable = lambda {|filepath|
            File.basename(filepath)[-4,4]==".txt" or
            File.basename(filepath)[-4,4]==".eml" or
            File.basename(filepath)[-4,4]==".jpg" or
            File.basename(filepath)[-4,4]==".png" or
            File.basename(filepath)[-4,4]==".gif" or
            File.basename(filepath)[-7,7]==".webloc"
        }

        openableFiles = files
                .select{|filepath| fileIsOpenable.call(filepath) }


        filesWithoutTheDescription = files
                .select{|filepath| !File.basename(filepath).include?('description.txt') }

        extractURLFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            line = contents.lines.first.strip
            line = Jupiter::simplifyURLCarryingString(line)
            return nil if !line.start_with?("http")
            line
        }

        extractLineFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            contents.lines.first.strip
        }

        if files.size==0 then
            # There is one open able file in the folder
            metadata["target-type"] = "virtually-empty-wave-folder"
            if metadata["announce"].nil? then
                metadata["announce"] = folderpath
            end
            return metadata
        end

        if files.size==1 and ( url = extractURLFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "url"
            metadata["url"] = url
            if metadata["announce"].nil? then
                metadata["announce"] = url
            end
            return metadata
        end

        if files.size==1 and ( line = extractLineFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "line"
            metadata["text"] = line
            if metadata["announce"].nil? then
                metadata["announce"] = line
            end
            return metadata
        end

        if files.size==1 and openableFiles.size==1 then
            filepath = files.first
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filepath
            if metadata["announce"].nil? then
                metadata["announce"] = File.basename(filepath)
            end
            return metadata
        end

        if files.size==1 and openableFiles.size!=1 then
            filepath = files.first
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "One non-openable file in #{File.basename(folderpath)}"
            end
            return metadata
        end

        if files.size > 1 and filesWithoutTheDescription.size==1 and fileIsOpenable.call(filesWithoutTheDescription.first) then
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filesWithoutTheDescription.first
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            return metadata
        end

        if files.size > 1 then
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            return metadata
        end
    end

    def self.openActionOnMetadata(metadata)
        if metadata["target-type"]=="folder" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="openable-file" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="line" then

        end
        if metadata["target-type"]=="url" then
            system("open '#{metadata["url"]}'")
        end
        if metadata["target-type"]=="virtually-empty-wave-folder" then

        end
    end
end

# GenericTimeTracking::status(uuid): [boolean, null or unixtime]
# GenericTimeTracking::start(uuid)
# GenericTimeTracking::stop(uuid)
# GenericTimeTracking::metric2(uuid, low, high, hourstoMinusOne)
# GenericTimeTracking::timings(uuid)

class GenericTimeTracking
    def self.status(uuid)
        JSON.parse(FKVStore::getOrDefaultValue("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", "[false, null]"))
    end

    def self.start(uuid)
        status = GenericTimeTracking::status(uuid)
        return if status[0]
        status = [true, Time.new.to_i]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.stop(uuid)
        status = GenericTimeTracking::status(uuid)
        return if !status[0]
        timespan = Time.new.to_i - status[1]
        FIFOQueue::push(CATALYST_COMMON_XCACHE_REPOSITORY, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
        status = [false, nil]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.metric2(uuid, low, high, hourstoMinusOne)
        adaptedTimespanInSeconds = FIFOQueue::values(CATALYST_COMMON_XCACHE_REPOSITORY, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                timespan * Math.exp(-ageInDays)
            }
            .inject(0, :+)
        adaptedTimespanInHours = adaptedTimespanInSeconds.to_f/3600
        low + (high-low)*Math.exp(-adaptedTimespanInHours.to_f/hourstoMinusOne)
    end

    def self.timings(uuid)
        FIFOQueue::values(CATALYST_COMMON_XCACHE_REPOSITORY, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
    end
end

# CatalystDevOps::today()
# CatalystDevOps::getArchiveSizeInMegaBytes()
# CatalystDevOps::getFirstDiveFirstLocationAtLocation(location)
# CatalystDevOps::archivesGarbageCollection(verbose): Int # number of items removed
# CatalystDevOps::xcacheGarbageCollection()

class CatalystDevOps

    def self.today()
        DateTime.now.to_date.to_s
    end

    def self.getFirstDiveFirstLocationAtLocation(location)
        if File.file?(location) then
            location
        else
            locations = Dir.entries(location)
                .select{|filename| filename!='.' and filename!='..' }
                .sort
                .map{|filename| "#{location}/#{filename}" }
            if locations.size==0 then
                location
            else
                locationsdirectories = locations.select{|location| File.directory?(location) }
                if locationsdirectories.size>0 then
                    CatalystDevOps::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.getFilepathAgeInDays(filepath)
        (Time.new.to_i - File.mtime(filepath).to_i).to_f/86400
    end

    # -------------------------------------------
    # Archives

    def self.getArchiveSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    def self.archivesGarbageCollectionStandard(verbose)
        answer = 0
        while CatalystDevOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            puts "Garbage Collection: Removing: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
            answer = answer + 1
        end
        answer
    end

    def self.archivesGarbageCollectionFast(verbose, sizeEstimationInMegaBytes)
        answer = 0
        while sizeEstimationInMegaBytes > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            if File.file?(location) then
                sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
            end
            puts "Garbage Collection: Removing: #{location}" if verbose
            LucilleCore::removeFileSystemLocation(location)
            answer = answer + 1
        end
        answer
    end

    def self.archivesGarbageCollection(verbose)
        answer = 0
        while CatalystDevOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            answer = answer + CatalystDevOps::archivesGarbageCollectionFast(verbose, CatalystDevOps::getArchiveSizeInMegaBytes())
        end
        answer
    end

    # -------------------------------------------
    # xcache

    def self.xcacheDataFilepathEnumerator(subfolder)
        Enumerator.new do |filepaths|
            Find.find("#{CATALYST_COMMON_XCACHE_REPOSITORY}/#{subfolder}") do |path|
                if path[-5, 5] == '.data' then
                    filepaths << path
                end
            end
        end
    end

    def self.xcacheFolderpathEnumerator(subfolder)
        Enumerator.new do |paths|
            Find.find("#{CATALYST_COMMON_XCACHE_REPOSITORY}/#{subfolder}") do |path|
                next if !File.directory?(path)
                paths << path
            end
        end
    end

    def self.xcacheGarbageCollection(subfolder = "")
        CatalystDevOps::xcacheDataFilepathEnumerator(subfolder).each{|filepath|
            if CatalystDevOps::getFilepathAgeInDays(filepath) > 60 then
                puts "removing: #{filepath}"
                FileUtils.rm(filepath)
            end
        }
        CatalystDevOps::xcacheFolderpathEnumerator(subfolder).each{|path|
            next if Dir.entries(path).select{|filepath| filepath[0,1]!="." }.size>0
            LucilleCore::removeFileSystemLocation(path)
        }
    end

end
