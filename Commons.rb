#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# ----------------------------------------------------------------

CATALYST_COMMON_AGENT_DATA_FOLDERPATH = "/Galaxy/Catalyst-Data/Agents-Data"
CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "/Galaxy/Catalyst-Data/Archives-Timeline"
CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Stream"
CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/Open-Projects"
CATALYST_COMMON_PATH_TO_DATA_LOG = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/DataLog"

# ----------------------------------------------------------------

# DataLogUtils::pathToActiveDataLogIndexFolder()
# DataLogUtils::commitCatalystObjectToDisk(object)
# DataLogUtils::getDataLog()
# DataLogUtils::dataLog2IntermediaryStructure(dataLog)
# DataLogUtils::intermediaryStructure2DataSet(intermediaryStructure)
# DataLogUtils::getDataSetFromDisk()

class DataLogUtils
    def self.pathToActiveDataLogIndexFolder()
        LucilleCore::indexsubfolderpath(CATALYST_COMMON_PATH_TO_DATA_LOG)
    end

    def self.commitCatalystObjectToDisk(object)
        folderpath = DataLogUtils::pathToActiveDataLogIndexFolder()
        filepath = "#{folderpath}/#{LucilleCore::timeStringL22()}.json"
        File.open(filepath, "w"){ |f| f.write(JSON.pretty_generate(object)) }
    end

    def self.getDataLog()
        objects = []
        Find.find(CATALYST_COMMON_PATH_TO_DATA_LOG) do |path|
            next if !File.file?(path)
            next if File.basename(path)[-5,5] != '.json'
            objects << JSON.parse(IO.read(path))
        end
        objects
    end

    def self.dataLog2IntermediaryStructure(dataLog)
        structure = {}
        dataLog.each{|object|
            structure[object["uuid"]] = object # Here we do not really need to check relative times because objects are naturally ordered by creation time due to ordering in the file system
        }
        structure
    end

    def self.intermediaryStructure2DataSet(intermediaryStructure)
        intermediaryStructure.values
    end

    def self.getDataSetFromDisk()
        dataLog = DataLogUtils::getDataLog()
        intermediaryStructure = DataLogUtils::dataLog2IntermediaryStructure(dataLog)
        DataLogUtils::intermediaryStructure2DataSet(intermediaryStructure)
    end
end

# Saturn::currentHour()
# Saturn::currentDay()
# Saturn::simplifyURLCarryingString(string)
# Saturn::traceToRealInUnitInterval(trace)
# Saturn::traceToMetricShift(trace)
# Saturn::deathObject(uuid)

class Saturn

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
                    return Saturn::simplifyURLCarryingString(string)
                end
            }
        string
    end

    def self.traceToRealInUnitInterval(trace)
        ( '0.'+Digest::SHA1.hexdigest(trace).gsub(/[^\d]/, '') ).to_f
    end

    def self.traceToMetricShift(trace)
        0.001*Saturn::traceToRealInUnitInterval(trace)
    end

    def self.deathObject(uuid)
        {
            "uuid"  => uuid,
            "death" => true
        }
    end
end

# DoNotShowUntil::set(uuid, datetime)
# DoNotShowUntil::transform(objects)

class DoNotShowUntil
    @@mapping = {}

    def self.init()
        @@mapping = JSON.parse(IO.read("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/do-not-show-until.json"))
    end

    def self.set(uuid, datetime)
        @@mapping[uuid] = datetime
        File.open("#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/do-not-show-until.json", "w"){|f| f.puts(JSON.pretty_generate(@@mapping)) }
    end

    def self.isactive(object)
        return true if @@mapping[object["uuid"]].nil?
        return true if DateTime.now() >= DateTime.parse(@@mapping[object["uuid"]])
        false
    end

    def self.transform(objects)
        objects.map{|object|
            if !DoNotShowUntil::isactive(object) then
                object["do-not-show-metric"] = object["metric"]
                object["do-not-show-until-datetime"] = @@mapping[object["uuid"]]
                # next we try to promote any do-not-show-until-datetime contained in a shceduler of a wave item, with a target in the future
                if object["do-not-show-until-datetime"].nil? and object["schedule"] and object["schedule"]["do-not-show-until-datetime"] and (Time.new.to_s < object["schedule"]["do-not-show-until-datetime"]) then
                    object["do-not-show-until-datetime"] = object["schedule"]["do-not-show-until-datetime"]
                end
                object["metric"] = 0
            end
            object
        }
    end
end

class RequirementsOperator

    @@pathToDataFile = nil
    @@data = nil

    def self.init()
        @@pathToDataFile = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/requirements.json"
        @@data = JSON.parse(IO.read(@@pathToDataFile))
    end

    def self.saveDataToDisk()
        objects = CatalystDataOperator::catalystObjects()
        uuidsInFile = @@data["items-requirements-distribution"].keys
        uuidsInFile.each{|uuid|
            if !objects.map{|object| object["uuid"] }.include?(uuid) then
                @@data["items-requirements-distribution"].delete(uuid)
            end
            if @@data["items-requirements-distribution"][uuid].size==0 then
                @@data["items-requirements-distribution"].delete(uuid)
            end
        }
        requirements = @@data['items-requirements-distribution'].values.flatten.uniq
        @@data['requirements-status'].keys.each{|r|
            if !requirements.include?(r) then
                @@data['requirements-status'].delete(r)
            end
        }
        File.open(@@pathToDataFile, 'w') {|f| f.puts(JSON.pretty_generate(@@data)) }
    end

    def self.getObjectRequirements(uuid)
        @@data['items-requirements-distribution'][uuid] || []
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        @@data['requirements-status'][requirement].nil? or @@data['requirements-status'][requirement]
    end

    def self.objectMeetsRequirements(uuid)
        RequirementsOperator::getObjectRequirements(uuid)
            .all?{|requirement| RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.addObjectRequirement(uuid,requirement)
        requirements = @@data['items-requirements-distribution'][uuid] || []
        requirements << requirement
        requirements = requirements.uniq.sort
        @@data['items-requirements-distribution'][uuid] = requirements
        RequirementsOperator::saveDataToDisk()
    end

    def self.removeObjectRequirement(uuid,requirement)
        requirements = @@data['items-requirements-distribution'][uuid] || []
        requirements.delete(requirement)
        requirements = requirements.uniq.sort
        @@data['items-requirements-distribution'][uuid] = requirements
        RequirementsOperator::saveDataToDisk()
    end

    def self.setRequirementOn(requirement)
        @@data['requirements-status'][requirement] = true
        RequirementsOperator::saveDataToDisk()
    end

    def self.setRequirementOff(requirement)
        @@data['requirements-status'][requirement] = false
        RequirementsOperator::saveDataToDisk()
    end

    def self.allRequirements()
        @@data['items-requirements-distribution'].values.flatten.uniq
    end

    def self.currentlyUnsatisfifiedRequirements()
        RequirementsOperator::allRequirements().select{|requirement| !RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.selectExistingRequirement()
        requirements = @@data['requirements-status'].keys
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("requirement", requirements)
    end
end

# TodayOrNotToday::notToday(uuid)
# TodayOrNotToday::todayOk(uuid)

class TodayOrNotToday
    def self.notToday(uuid)
        KeyValueStore::set(nil, "9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{Saturn::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        KeyValueStore::getOrNull(nil, "9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{Saturn::currentDay()}:#{uuid}").nil?
    end
end

# KillersCurvesManagement::getCurve(folderpath)
# KillersCurvesManagement::shiftCurve(curve)
# KillersCurvesManagement::computeIdealCountFromCurve(curve)
# KillersCurvesManagement::computeMetric(currentCount, idealCount)
# KillersCurvesManagement::shiftCurveIfOpportunity(folderpath, currentCount1)

# KillersCurvesManagement::trueIfCanShiftCurveForFolderpath(folderpath)
# KillersCurvesManagement::setLastCurveChangeDateForFolderpath(folderpath, date)

class KillersCurvesManagement
    def self.trueIfCanShiftCurveForFolderpath(folderpath)
        KeyValueStore::getOrNull(nil, "53f628bf-a119-4d9d-b48c-664c81b69047:#{folderpath}") != Saturn::currentDay()
    end

    def self.setLastCurveChangeDateForFolderpath(folderpath, date)
        KeyValueStore::set(nil, "53f628bf-a119-4d9d-b48c-664c81b69047:#{folderpath}", date)
    end

    def self.getCurve(folderpath)
        filename = Dir.entries(folderpath)
            .select{|filename| filename[0,1] != "." }
            .sort
            .last
        JSON.parse(IO.read("#{folderpath}/#{filename}"))
    end

    def self.shiftCurve(curve)
        curve = curve.clone
        curve["starting-count"] = curve["starting-count"]-10
        curve
    end

    def self.computeIdealCountFromCurve(curve)
        curve["starting-count"] - curve["starting-count"]*(Time.new.to_i - curve["starting-unixtime"]).to_f/(curve["ending-unixtime"] - curve["starting-unixtime"])
    end

    def self.computeMetric(currentCount, idealCount)
        currentCount.to_f/(0.01*idealCount) - (idealCount*0.99).to_f/(0.01*idealCount)
    end

    def self.shiftCurveIfOpportunity(folderpath, currentCount1)
        return if !KillersCurvesManagement::trueIfCanShiftCurveForFolderpath(folderpath)
        curve1 = KillersCurvesManagement::getCurve(folderpath)
        idealCount1 = KillersCurvesManagement::computeIdealCountFromCurve(curve1)
        metric1 = KillersCurvesManagement::computeMetric(currentCount1, idealCount1)
        if metric1 < 0.2 then
            curve2 = KillersCurvesManagement::shiftCurve(curve1)
            idealCount2 = KillersCurvesManagement::computeIdealCountFromCurve(curve2)
            metric2 = KillersCurvesManagement::computeMetric(currentCount1, idealCount2)
            if metric2 < 0.2 then
                puts "#{folderpath}, shifting curve on disk (metric1: #{metric1} -> #{metric2})"
                File.open("#{folderpath}/curve-#{LucilleCore::timeStringL22()}.json", "w"){|f| f.puts( JSON.pretty_generate(curve2) ) }
                KillersCurvesManagement::setLastCurveChangeDateForFolderpath(folderpath, Saturn::currentDay())
            end
        end
    end
end

# Collections::init()
# Collections::addObjectToCollection(uuid, collection)
# Collections::getCollectionUUIDs(collection)
# Collections::getCollections()
# Collections::selectExistingCollection()
# Collections::selectExistingOrNewCollection()
# Collections::objectIsNotInAnyCollection(uuid)

class Collections
    @@pathToDataFile = nil
    @@data = nil

    def self.init()
        @@pathToDataFile = "#{CATALYST_COMMON_AGENT_DATA_FOLDERPATH}/collections.json"
        @@data = JSON.parse(IO.read(@@pathToDataFile))
    end

    def self.saveDataToDisk()
        objects = CatalystDataOperator::catalystObjects()
        collections = @@data.keys
        collections.each{|collection|
            @@data[collection] = @@data[collection].select{|uuid| objects.map{|object| object["uuid"] }.include?(uuid) }
        }
        File.open(@@pathToDataFile, 'w') {|f| f.puts(JSON.pretty_generate(@@data)) }
    end

    def self.addObjectToCollection(uuid, collection)
        @@data[collection] = [] if @@data[collection].nil?
        @@data[collection] << uuid
        @@data[collection] = @@data[collection].uniq
        Collections::saveDataToDisk()
    end

    def self.getCollectionUUIDs(collection)
        @@data[collection]
    end

    def self.getCollections()
        @@data.keys
    end

    def self.selectExistingCollection()
        collections = @@data.keys
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collection", collections)
    end

    def self.selectExistingOrNewCollection()
        collections = @@data.keys
        collection = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("collection", collections)
        if collection.nil? then
            collection = LucilleCore::askQuestionAnswerAsString("new collection: ")
        end
        collection
    end

    def self.objectIsNotInAnyCollection(uuid)
        @@data.keys.all?{|collection| !@@data[collection].include?(uuid) }
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
            puts metadata["text"]
        end
        if metadata["target-type"]=="url" then
            system("open '#{metadata["url"]}'")
        end
        if metadata["target-type"]=="virtually-empty-wave-folder" then
            puts metadata["announce"]
        end
    end
end

# GenericTimeTracking::status(uuid): [boolean, null or unixtime]
# GenericTimeTracking::start(uuid)
# GenericTimeTracking::stop(uuid)
# GenericTimeTracking::metric2(uuid, low, high, hourstoMinusOne)

class GenericTimeTracking
    def self.status(uuid)
        JSON.parse(KeyValueStore::getOrDefaultValue(nil, "status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", "[false, null]"))
    end

    def self.start(uuid)
        status = GenericTimeTracking::status(uuid)
        return if status[0]
        status = [true, Time.new.to_i]
        KeyValueStore::set(nil, "status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.stop(uuid)
        status = GenericTimeTracking::status(uuid)
        return if !status[0]
        timespan = Time.new.to_i - status[1]
        FIFOQueue::push(nil, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}", [Time.new.to_i, timespan])
        status = [false, nil]
        KeyValueStore::set(nil, "status:d0742c76-b83a-4fa4-9264-cfb5b21f8dc4:#{uuid}", JSON.generate(status))
    end

    def self.metric2(uuid, low, high, hourstoMinusOne)
        adaptedTimespanInSeconds = FIFOQueue::values(nil, "timespans:f13bdb69-9313-4097-930c-63af0696b92d:#{uuid}")
            .map{|pair|
                unixtime = pair[0]
                timespan = pair[1]
                ageInSeconds = Time.new.to_i - unixtime
                ageInDays = ageInSeconds.to_f/86400
                timespan * Math.exp(ageInDays*2)
            }
            .inject(0, :+)
        adaptedTimespanInHours = adaptedTimespanInSeconds.to_f/3600
        low + (high-low)*Math.exp(-adaptedTimespanInHours.to_f/hourstoMinusOne)
    end
end

# CatalystArchivesOps::today()
# CatalystArchivesOps::getArchiveSizeInMegaBytes()
# CatalystArchivesOps::getFirstDiveFirstLocationAtLocation(location)
# CatalystArchivesOps::archivesGarbageCollection(verbose): Int # number of items removed

class CatalystArchivesOps

    def self.today()
        DateTime.now.to_date.to_s
    end

    def self.getArchiveSizeInMegaBytes()
        LucilleCore::locationRecursiveSize(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH).to_f/(1024*1024)
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
                    CatalystArchivesOps::getFirstDiveFirstLocationAtLocation(locationsdirectories.first)
                else
                    locations.first
                end
            end
        end
    end

    def self.archivesGarbageCollectionStandard(verbose)
        answer = 0
        while CatalystArchivesOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystArchivesOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
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
            location = CatalystArchivesOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
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
        while CatalystArchivesOps::getArchiveSizeInMegaBytes() > 1024 do # Gigabytes of Archives
            location = CatalystArchivesOps::getFirstDiveFirstLocationAtLocation(CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH)
            break if location == CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH
            answer = answer + CatalystArchivesOps::archivesGarbageCollectionFast(verbose, CatalystArchivesOps::getArchiveSizeInMegaBytes())
        end
        answer
    end

end
