#!/usr/bin/ruby

# encoding: UTF-8

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

# ----------------------------------------------------------------

CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "/Galaxy/DataBank/Catalyst/Archives-Timeline"
CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER = "/Galaxy/DataBank/Catalyst/Stream"

# Saturn::currentHour()
# Saturn::currentDay()
# Saturn::simplifyURLCarryingString(string)

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
end

# DoNotShowUntil::set(uuid, datetime)
# DoNotShowUntil::transform(objects)

class DoNotShowUntil
    @@mapping = {}

    def self.init()
        @@mapping = JSON.parse(IO.read("/Galaxy/DataBank/Catalyst/do-not-show-until.json"))
    end

    def self.set(uuid, datetime)
        @@mapping[uuid] = datetime
        File.open("/Galaxy/DataBank/Catalyst/do-not-show-until.json", "w"){|f| f.puts(JSON.pretty_generate(@@mapping)) }
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
        @@pathToDataFile = "/Galaxy/DataBank/Catalyst/requirements/requirements-structure.json"
        @@data = JSON.parse(IO.read(@@pathToDataFile))
    end

    def self.saveDataToDisk()
        File.open(@@pathToDataFile, 'w') {|f| f.puts(JSON.pretty_generate(@@data)) }
    end

    def self.getObjectRequirements(uuid)
        @@data['items-requirements-distribution'][uuid] || []
    end

    def self.requirementIsCurrentlySatisfied(requirement)
        @@data['requirements-status-timeline'][requirement].nil? or @@data['requirements-status-timeline'][requirement]
    end

    def self.meetRequirements(uuid)
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
        @@data['requirements-status-timeline'][requirement] = true
        RequirementsOperator::saveDataToDisk()
    end

    def self.setRequirementOff(requirement)
        @@data['requirements-status-timeline'][requirement] = false
        RequirementsOperator::saveDataToDisk()
    end

    def self.allRequirements()
        @@data['items-requirements-distribution'].values.flatten.uniq
    end

    def self.currentlyUnsatisfifiedRequirements()
        RequirementsOperator::allRequirements().select{|requirement| !RequirementsOperator::requirementIsCurrentlySatisfied(requirement) }
    end

    def self.selectExistingRequirement()
        requirements = @@data['requirements-status-timeline'].keys
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
        @@pathToDataFile = "/Galaxy/DataBank/Catalyst/collections.json"
        @@data = JSON.parse(IO.read(@@pathToDataFile))
    end

    def self.saveDataToDisk()
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

        if folderpath.include?("#{WAVE_DATABANK_WAVE_FOLDER_PATH}/OpsLine-Active") then
            metadata = {}
            filepaths = FolderProbe::nonDotFilespathsAtFolder(folderpath)
            if filepaths.any?{|filepath| File.basename(filepath)=="catalyst-description.txt" } then
                metadata["announce"] = IO.read(filepaths.select{|filepath| File.basename(filepath)=="catalyst-description.txt" }.first).strip
            end
            filepaths = filepaths
                .select{|filename| File.basename(filename)[0, 4] != 'wave' }
                .select{|filename| File.basename(filename)[0, 8] != 'catalyst' }
            if filepaths.size == 0 then
                if metadata["announce"].start_with?("http") then 
                    metadata["target-type"] = "url"
                    metadata["url"] = metadata["announce"]
                else
                    metadata["target-type"] = "virtually-empty-wave-folder"
                    if metadata["announce"].nil? then
                        metadata["announce"] = "virtually-empty-wave-folder without catalyst-description.txt"
                    end
                end
            end
            if filepaths.size == 1 then
                metadata["target-type"] = "folder"
                metadata["target-location"] = folderpath 
                if metadata["announce"].nil? then
                    metadata["announce"] = "#{File.basename(filepaths[0])}"
                end
            end
            if filepaths.size > 1 then
                metadata["target-type"] = "folder"
                metadata["target-location"] = "folderpath" 
                if metadata["announce"].nil? then
                    metadata["announce"] = "file-occupied wave-folder without catalyst-description.txt"
                end
                metadata["filepaths"] = filepaths
            end
            return metadata
        end

        filepaths = FolderProbe::nonDotFilespathsAtFolder(folderpath)
        if filepaths.size==1 then
            filepath = filepaths[0]
            if filepath[-4,4]==".txt" then
                if IO.read(filepath).strip.lines.to_a.size==1 then
                    line = IO.read(filepath).strip
                    line = Saturn::simplifyURLCarryingString(line)
                    if line.start_with?("http") then
                        return {
                            "target-type" => "url",
                            "url" => line,
                            "announce" => line
                        }
                    else
                        return {
                            "target-type" => "line",
                            "text" => line,
                            "announce" => "line: #{line}"
                        }
                    end
                else
                    return {
                        "target-type" => "openable-file",
                        "target-location" => filepath,
                        "announce" => File.basename(filepath)
                    }
                end
            end
            if filepath[-7,7]==".webloc" and !filepath.include?("'") then
                return {
                    "target-type" => "openable-file",
                    "target-location" => filepath,
                    "announce" => File.basename(filepath)
                }
            end
            return {
                "target-type" => "folder",
                "target-location" => folderpath,
                "announce" => File.basename(filepath)
            }
        else
            return {
                "target-type" => "folder",
                "target-location" => folderpath,
                "announce" => "multiple files in #{File.basename(folderpath)}"
            }
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
