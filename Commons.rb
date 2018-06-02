#!/usr/bin/ruby

# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "Constants.rb"
require_relative "Events.rb"
require_relative "Flock.rb"
require_relative "FlockBasedServices.rb"

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

# CommonsUtils::isLucille18()
# CommonsUtils::isActiveInstance(runId)
# CommonsUtils::currentHour()
# CommonsUtils::currentDay()
# CommonsUtils::simplifyURLCarryingString(string)
# CommonsUtils::traceToRealInUnitInterval(trace)
# CommonsUtils::traceToMetricShift(trace)
# CommonsUtils::realNumbersToZeroOne(x, origin, unit)
# CommonsUtils::codeToDatetimeOrNull(code)

class CommonsUtils

    def self.isLucille18()
        ENV["COMPUTERLUCILLENAME"]==Config::get("PrimaryComputerName")
    end

    def self.isActiveInstance(runId)
        IO.read("#{CATALYST_COMMON_DATABANK_FOLDERPATH}/run-identifier.data")==runId
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
                    return CommonsUtils::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.001*CommonsUtils::traceToRealInUnitInterval(trace)
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
        FlockOperator::flockObjects().map{|object| RequirementsOperator::getObjectRequirements(object["uuid"]) }.flatten.uniq
    end

    def self.selectRequirementFromExistingRequirementsOrNull()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", RequirementsOperator::getAllRequirements())
    end

    def self.transform()
        FlockOperator::flockObjects().each{|object|
            if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end
end

# TodayOrNotToday::notToday(uuid)
# TodayOrNotToday::todayOk(uuid)
# TodayOrNotToday::transform()

class TodayOrNotToday
    def self.notToday(uuid)
        FKVStore::set("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        FKVStore::getOrNull("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}").nil?
    end
    def self.transform()
        FlockOperator::flockObjects().each{|object|
            if !TodayOrNotToday::todayOk(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
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
            line = CommonsUtils::simplifyURLCarryingString(line)
            return nil if !line.start_with?("http")
            line
        }

        extractLineFromFileMaybe = lambda{|filepath|
            return nil if filepath[-4,4] != ".txt"
            contents = IO.read(filepath)
            return nil if contents.lines.to_a.size != 1
            contents.lines.first.strip
        }

        if File.exists?("#{folderpath}/email-metatada-emailuid.txt") then
            metadata["target-type"] = "openable-file"
            emailFilename = Dir.entries(folderpath).select{|filename| filename[-4, 4]==".eml" }.first
            metadata["target-location"] = "#{folderpath}/#{emailFilename}"
            if metadata["announce"].nil? then
                metadata["announce"] = "[email]"
            end
            metadata["folderpath2metadata:case"] = "cf6f25cb"
            return metadata
        end

        if files.size==0 then
            # There is one open able file in the folder
            metadata["target-type"] = "virtually-empty-wave-folder"
            if metadata["announce"].nil? then
                metadata["announce"] = folderpath
            end
            metadata["folderpath2metadata:case"] = "b6e8ac55"
            return metadata
        end

        if files.size==1 and ( url = extractURLFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "url"
            metadata["url"] = url
            if metadata["announce"].nil? then
                metadata["announce"] = url
            end
            metadata["folderpath2metadata:case"] = "95e7dd30"
            return metadata
        end

        if files.size==1 and ( line = extractLineFromFileMaybe.call(files[0]) ) then
            filepath = files.first
            metadata["target-type"] = "line"
            metadata["text"] = line
            if metadata["announce"].nil? then
                metadata["announce"] = line
            end
            metadata["folderpath2metadata:case"] = "a888e991"
            return metadata
        end

        if files.size==1 and openableFiles.size==1 then
            filepath = files.first
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filepath
            if metadata["announce"].nil? then
                metadata["announce"] = File.basename(filepath)
            end
            metadata["folderpath2metadata:case"] = "54b1a4b5"
            return metadata
        end

        if files.size==1 and openableFiles.size!=1 then
            filepath = files.first
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "One non-openable file in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "439bba64"
            return metadata
        end

        if files.size > 1 and filesWithoutTheDescription.size==1 and fileIsOpenable.call(filesWithoutTheDescription.first) then
            metadata["target-type"] = "openable-file"
            metadata["target-location"] = filesWithoutTheDescription.first
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "29d2dc25"
            return metadata
        end

        if files.size > 1 then
            metadata["target-type"] = "folder"
            metadata["target-location"] = folderpath
            if metadata["announce"].nil? then
                metadata["announce"] = "Multiple files in #{File.basename(folderpath)}"
            end
            metadata["folderpath2metadata:case"] = "f6a683b0"
            return metadata
        end
    end

    def self.openActionOnMetadata(metadata)
        if metadata["target-type"]=="folder" then
            if File.exists?(metadata["target-location"]) then
                system("open '#{metadata["target-location"]}'")
            else
                puts "Error: folder #{metadata["target-location"]} doesn't exist."
                LucilleCore::pressEnterToContinue()
            end
        end
        if metadata["target-type"]=="openable-file" then
            system("open '#{metadata["target-location"]}'")
        end
        if metadata["target-type"]=="line" then

        end
        if metadata["target-type"]=="url" then
            if CommonsUtils::isLucille18() then
                system("open '#{metadata["url"]}'")
            else
                system("open -na 'Google Chrome' --args --new-window '#{metadata["url"]}'")
            end
        end
        if metadata["target-type"]=="virtually-empty-wave-folder" then

        end
    end
end

# GenericTimeTracking::status(uuid): [boolean, null or unixtime]
# GenericTimeTracking::start(uuid)
# GenericTimeTracking::stop(uuid)
# GenericTimeTracking::adaptedTimespanInSeconds(uuid)
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
        MiniFIFOQ::push("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
        status = [false, nil]
        FKVStore::set("status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.adaptedTimespanInSeconds(uuid)
        adaptedTimespanInSeconds = MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                timespan * Math.exp(-ageInDays)
            }
            .inject(0, :+)
    end

    def self.metric2(uuid, low, high, hourstoMinusOne)
        adaptedTimespanInSeconds = GenericTimeTracking::adaptedTimespanInSeconds(uuid)
        adaptedTimespanInHours = adaptedTimespanInSeconds.to_f/3600
        low + (high-low)*Math.exp(-adaptedTimespanInHours.to_f/hourstoMinusOne)
    end

    def self.timings(uuid)
        MiniFIFOQ::values("timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
    end
end

# CatalystDevOps::today()
# CatalystDevOps::getFirstDiveFirstLocationAtLocation(location)
# CatalystDevOps::getFilepathAgeInDays(filepath)

# CatalystDevOps::getArchiveTimelineSizeInMegaBytes()
# CatalystDevOps::archivesTimelineGarbageCollectionStandard(): Array[String] 
# CatalystDevOps::archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes): Array[String] 
# CatalystDevOps::archivesTimelineGarbageCollection(): Array[String]

# CatalystDevOps::eventsTimelineGarbageCollection()

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

    def self.getArchiveTimelineSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
    end

    def self.archivesTimelineGarbageCollectionStandard()
        lines = []
        while CatalystDevOps::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            lines << location
            LucilleCore::removeFileSystemLocation(location)
        end
        lines
    end

    def self.archivesTimelineGarbageCollectionFast(sizeEstimationInMegaBytes)
        lines = []
        while sizeEstimationInMegaBytes > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            if File.file?(location) then
                sizeEstimationInMegaBytes = sizeEstimationInMegaBytes - File.size(location).to_f/(1024*1024)
            end
            lines << location
            LucilleCore::removeFileSystemLocation(location)
        end
        line
    end

    def self.archivesTimelineGarbageCollection()
        lines = []
        while CatalystDevOps::getArchiveTimelineSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystDevOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            CatalystDevOps::archivesTimelineGarbageCollectionFast(CatalystDevOps::getArchiveTimelineSizeInMegaBytes())
                .each{|line| lines << line }
        end
        lines
    end

    # -------------------------------------------
    # Events Timeline

    def self.canRemoveEvent(head, tail)
        if head["event-type"] == "Catalyst:Catalyst-Object:1" then
            return tail.any?{|e| e["event-type"]=="Catalyst:Catalyst-Object:1" and e["object"]["uuid"]==head["object"]["uuid"] }
        end
        if head["event-type"] == "Catalyst:Destroy-Catalyst-Object:1" then
            return tail.any?{|e| e["event-type"]=="Catalyst:Catalyst-Object:1" and e["object"]["uuid"]==head["object-uuid"] }
        end
        if head["event-type"] == "Catalyst:Metadata:DoNotShowUntilDateTime:1" then
            return DateTime.parse(head["datetime"]).to_time.to_i < Time.new.to_i
        end
        if head["event-type"] == "Flock:KeyValueStore:Set:1" then
            return tail.any?{|e| e["event-type"]=="Flock:KeyValueStore:Set:1" and e["key"]==head["key"] }
        end
        raise "Don't know how to garbage collect head: \n#{JSON.pretty_generate(head)}"
    end

    def self.eventsTimelineGarbageCollection()
        lines = []
        events = EventsManager::eventsEnumerator().to_a
        while events.size>=2 do
            event = events.shift
            if CatalystDevOps::canRemoveEvent(event, events) then
                eventfilepath = event[":filepath:"]
                lines << eventfilepath
                FileUtils.rm(eventfilepath)
            end
        end
        lines
    end
end

# -------------------------------------------------------------

# Collections was born out of what was originally known as Threads and Projects

# -------------------------------------------------------------

# OperatorCollections::collectionsFolderpaths()
# OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)
# OperatorCollections::folderPath2CollectionName(folderpath)
# OperatorCollections::folderPath2CollectionObject(folderpath)
# OperatorCollections::collectionUUID2FolderpathOrNull(uuid)
# OperatorCollections::collectionsUUIDs()
# OperatorCollections::collectionsNames()
# OperatorCollections::collectionUUID2NameOrNull(collectionuuid)

# OperatorCollections::createNewCollection_WithNameAndStyle(collectionname, style)

# OperatorCollections::addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
# OperatorCollections::addObjectUUIDToCollectionInteractivelyChosen(objectuuid, threaduuid)
# OperatorCollections::collectionCatalystObjectUUIDs(threaduuid)
# OperatorCollections::allCollectionsCatalystUUIDs()

# OperatorCollections::setCollectionStyle(collectionuuid, style)
# OperatorCollections::getCollectionStyle(collectionuuid)

# OperatorCollections::transform()
# OperatorCollections::sendCollectionToBinTimeline(uuid)
# OperatorCollections::dailyCommitmentInHours()

class OperatorCollections
    def self.collectionsFolderpaths()
        Dir.entries(CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH)
            .sort
            .select{|filename| filename[0,1]!="." }
            .map{|filename| "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{filename}" }
    end

    def self.collectionsUUIDs()
        OperatorCollections::collectionsFolderpaths().map{|folderpath| OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath) }
    end

    def self.collectionsNames()
        OperatorCollections::collectionsFolderpaths().map{|folderpath| OperatorCollections::folderPath2CollectionName(folderpath) }
    end

    def self.folderPath2CollectionUUIDOrNull(folderpath)
        IO.read("#{folderpath}/collection-uuid")
    end

    def self.folderPath2CollectionName(folderpath)
        IO.read("#{folderpath}/collection-name")
    end

    def self.collectionUUID2FolderpathOrNull(uuid)
        OperatorCollections::collectionsFolderpaths()
            .each{|folderpath|
                return folderpath if OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    def self.collectionUUID2NameOrNull(uuid)
        OperatorCollections::collectionsFolderpaths()
            .each{|folderpath|
                return IO.read("#{folderpath}/collection-name").strip if OperatorCollections::folderPath2CollectionUUIDOrNull(folderpath)==uuid
            }
        nil
    end

    # ---------------------------------------------------

    def self.createNewCollection_WithNameAndStyle(collectionname, style)
        collectionuuid = SecureRandom.hex(4)
        foldername = LucilleCore::timeStringL22()
        folderpath = "#{CATALYST_COMMON_COLLECTIONS_REPOSITORY_FOLDERPATH}/#{foldername}"
        FileUtils.mkpath folderpath
        File.open("#{folderpath}/collection-uuid", "w"){|f| f.write(collectionuuid) }
        File.open("#{folderpath}/collection-name", "w"){|f| f.write(collectionname) }
        File.open("#{folderpath}/collection-catalyst-uuids.json", "w"){|f| f.puts(JSON.generate([])) }
        FileUtils.touch("#{folderpath}/collection-text.txt")
        FileUtils.mkpath "#{folderpath}/documents"
        self.setCollectionStyle(collectionuuid, style)
        collectionuuid
    end

    # ---------------------------------------------------
    # collections uuids

    def self.addCatalystObjectUUIDToCollection(objectuuid, threaduuid)
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(threaduuid)
        arrayFilepath = "#{folderpath}/collection-catalyst-uuids.json"
        array = JSON.parse(IO.read(arrayFilepath))
        array << objectuuid 
        array = array.uniq
        File.open(arrayFilepath, "w"){|f| f.puts(JSON.generate(array)) }
    end

    def self.addObjectUUIDToCollectionInteractivelyChosen(objectuuid)
        collectionsuuids = OperatorCollections::collectionsUUIDs()
        collectionuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collections", collectionsuuids, lambda{ |collectionuuid| OperatorCollections::collectionUUID2NameOrNull(collectionuuid) })
        if collectionuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new collection ? ") then
                collectionname = LucilleCore::askQuestionAnswerAsString("collection name: ")
                style = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("style", ["THREAD", "PROJECT"])
                collectionuuid = OperatorCollections::createNewCollection_WithNameAndStyle(collectionname, style)
            else
                return
            end
        end
        OperatorCollections::addCatalystObjectUUIDToCollection(objectuuid, collectionuuid)
        collectionuuid
    end

    def self.collectionCatalystObjectUUIDs(threaduuid)
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(threaduuid)
        JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json"))
    end

    def self.allCollectionsCatalystUUIDs()
        OperatorCollections::collectionsFolderpaths()
            .map{|folderpath| JSON.parse(IO.read("#{folderpath}/collection-catalyst-uuids.json")) }
            .flatten
    end

    # ---------------------------------------------------
    # style

    def self.setCollectionStyle(collectionuuid, style)
        if !["THREAD", "PROJECT"].include?(style) then
            raise "Incorrect Style: #{style}, should be THREAD or PROJECT"
        end
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        File.open(filepath, "w"){|f| f.write(style) }
    end

    def self.getCollectionStyle(collectionuuid)
        folderpath = OperatorCollections::collectionUUID2FolderpathOrNull(collectionuuid)
        filepath = "#{folderpath}/collection-style"
        IO.read(filepath).strip        
    end

    # ---------------------------------------------------

    def self.transform()
        uuids = self.allCollectionsCatalystUUIDs()
        FlockOperator::flockObjects().each{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
            end
            FlockOperator::addOrUpdateObject(object)
        }
    end

    def self.sendCollectionToBinTimeline(uuid)
        sourcefilepath = OperatorCollections::collectionUUID2FolderpathOrNull(uuid)
        return if sourcefilepath.nil?
        time = Time.new
        targetFolder = "#{CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH}/#{time.strftime("%Y")}/#{time.strftime("%Y%m")}/#{time.strftime("%Y%m%d")}/#{time.strftime("%Y%m%d-%H%M%S-%6N")}"
        FileUtils.mkpath(targetFolder)
        puts "source: #{sourcefilepath}"
        puts "target: #{targetFolder}"
        LucilleCore::copyFileSystemLocation(sourcefilepath, targetFolder)
        LucilleCore::removeFileSystemLocation(sourcefilepath)
    end

    def self.dailyCommitmentInHours()
        6
    end

end

# -------------------------------------------------------------
