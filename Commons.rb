#!/usr/bin/ruby

# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require_relative "MiniFIFOQ.rb"

# ----------------------------------------------------------------

CATALYST_COMMON_DATABANK_FOLDERPATH = "/Galaxy/DataBank/Catalyst"
CATALYST_COMMON_CONFIG_FILEPATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Config.json"
CATALYST_COMMON_ARCHIVES_TIMELINE_FOLDERPATH = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Bin-Timeline"
CATALYST_COMMON_PATH_TO_STREAM_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Stream"
CATALYST_COMMON_PATH_TO_SWAT_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/SWAT"
CATALYST_COMMON_PATH_TO_OPEN_PROJECTS_DATA_FOLDER = "#{CATALYST_COMMON_DATABANK_FOLDERPATH}/Agents-Data/Open-Projects"
CATALYST_COMMON_PATH_TO_EVENTS_TIMELINE = "/Galaxy/DataBank/Catalyst/Events-Timeline"
CATALYST_COMMON_PATH_TO_EVENTS_BUFFER_IN = "/Galaxy/DataBank/Catalyst/Events-Buffer-In"

# ----------------------------------------------------------------

$flock = nil

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

# CommonsUtils::isPrimaryComputer()
# CommonsUtils::currentHour()
# CommonsUtils::currentDay()
# CommonsUtils::simplifyURLCarryingString(string)
# CommonsUtils::traceToRealInUnitInterval(trace)
# CommonsUtils::traceToMetricShift(trace)
# CommonsUtils::realNumbersToZeroOne(x, origin, unit)
# CommonsUtils::codeToDatetimeOrNull(code)

class CommonsUtils

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
# EventsManager::commitEventToBufferIn(event)
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
                event = JSON.parse(IO.read(path))
                event[":filepath:"] = path
                events << event
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
        $flock["kvstore"][key]
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

# FlockLoader::loadFlockFromDisk()

class FlockLoader
    def self.loadFlockFromDisk()
        flock = {}
        flock["objects"] = []
        flock["do-not-show-until-datetime-distribution"] = {}
        flock["kvstore"] = {}
        EventsManager::eventsEnumerator().each{|event| # for the moment we rely on the fact that they are loaded in the right order
            if event["event-type"] == "Catalyst:Catalyst-Object:1" then
                object = event["object"]
                flock["objects"].reject!{|o| o["uuid"]==object["uuid"] }
                flock["objects"] << object
                next
            end
            if event["event-type"] == "Catalyst:Destroy-Catalyst-Object:1" then
                objectuuid = event["object-uuid"]
                flock["objects"].reject!{|o| o["uuid"]==objectuuid }
                next
            end
            if event["event-type"] == "Catalyst:Metadata:DoNotShowUntilDateTime:1" then
                flock["do-not-show-until-datetime-distribution"][event["object-uuid"]] = event["datetime"]
                next
            end
            if event["event-type"] == "Flock:KeyValueStore:Set:1" then
                flock["kvstore"][event["key"]] = event["value"]
                next
            end
            raise "Don't know how to interpret event: \n#{JSON.pretty_generate(event)}"
        }
        $flock = flock
    end
end

FlockLoader::loadFlockFromDisk()

# PrimaryOperator::agents()
# PrimaryOperator::agentuuid2AgentData(agentuuid)
# PrimaryOperator::generalUpgrade()
# PrimaryOperator::putshelp()

class PrimaryOperator

    def self.agents()
        [
            {
                "agent-name"      => "GuardianTime",
                "agent-uid"       => "11fa1438-122e-4f2d-9778-64b55a11ddc2",
                "general-upgrade" => lambda { GuardianTime::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| GuardianTime::processObjectAndCommand(object, command) },
                "interface"       => lambda{ GuardianTime::interface() }
            },
            {
                "agent-name"      => "Kimchee",
                "agent-uid"       => "b343bc48-82db-4fa3-ac56-3b5a31ff214f",
                "general-upgrade" => lambda { Kimchee::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Kimchee::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Kinchee::interface() }
            },
            {
                "agent-name"      => "Ninja",
                "agent-uid"       => "d3d1d26e-68b5-4a99-a372-db8eb6c5ba58",
                "general-upgrade" => lambda { Ninja::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Ninja::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Ninja::interface() }
            },
            {
                "agent-name"      => "OpenProjects",
                "agent-uid"       => "30ff0f4d-7420-432d-b75b-826a2a8bc7cf",
                "general-upgrade" => lambda { OpenProjects::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| OpenProjects::processObjectAndCommand(object, command) },
                "interface"       => lambda{ OpenProjects::interface() }
            },
            {
                "agent-name"      => "Stream",
                "agent-uid"       => "73290154-191f-49de-ab6a-5e5a85c6af3a",
                "general-upgrade" => lambda { Stream::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Stream::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Stream::interface() }
            },
            {
                "agent-name"      => "TimeCommitments",
                "agent-uid"       => "03a8bff4-a2a4-4a2b-a36f-635714070d1d",
                "general-upgrade" => lambda { TimeCommitments::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| TimeCommitments::processObjectAndCommand(object, command) },
                "interface"       => lambda{ TimeCommitments::interface() }
            },
            {
                "agent-name"      => "Today",
                "agent-uid"       => "f989806f-dc62-4942-b484-3216f7efbbd9",
                "general-upgrade" => lambda { Today::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Today::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Today::interface() }
            },
            {
                "agent-name"      => "Vienna",
                "agent-uid"       => "2ba71d5b-f674-4daf-8106-ce213be2fb0e",
                "general-upgrade" => lambda { Vienna::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Vienna::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Vienna::interface() }
            },
            {
                "agent-name"      => "Wave",
                "agent-uid"       => "283d34dd-c871-4a55-8610-31e7c762fb0d",
                "general-upgrade" => lambda { Wave::generalUpgrade() },
                "object-command-processor"  => lambda{ |object, command| Wave::processObjectAndCommand(object, command) },
                "interface"       => lambda{ Wave::interface() }
            }
        ]
    end

    def self.agentuuid2AgentData(agentuuid)
        PrimaryOperator::agents()
            .select{|agentinterface| agentinterface["agent-uid"]==agentuuid }
            .first
    end

    def self.generalUpgrade()
        PrimaryOperator::agents().each{|agentinterface| agentinterface["general-upgrade"].call() }
    end

    def self.putshelp()
        puts "Special General Commands (view)"
        puts "    help"
        puts "    top"
        puts "    search <pattern>"
        puts "    l:show"
        puts "    r:on <requirement>"
        puts "    r:off <requirement>"
        puts "    r:show [requirement] # optional parameter # shows all the objects of that requirement"
        puts ""
        puts "Special General Commands (inserts)"
        puts "    wave: <description>"
        puts "    stream: <description>"
        puts "    open-project: <description>"
        puts ""
        puts "Special General Commands (special circumstances)"
        puts "    clear # clear the screen"
        puts "    interface # run the interface of a given agent"
        puts "    lib # Invoques the Librarian interactive"
        puts ""
        puts "Special Object Commands:"
        puts "    expose # pretty print the object"
        puts "    !today"
        puts "    l:add"
        puts "    r:add <requirement>"
        puts "    r:remove <requirement>"
        puts "    command ..."
        puts "    (+)datetimecode"
    end
end

# Lava::domains()
# Lava::getDomainActivityLastUnixtime(domain)

class Lava
    def self.domains()
        domains = $flock["objects"]
            .select{|object| object[":lava:"] }
            .map{|object| object[":lava:"]["domain"] }
            .uniq
        domains
            .sort{|d1, d2| Lava::getDomainActivityLastUnixtime(d1)<=>Lava::getDomainActivityLastUnixtime(d2) }
            .reverse
    end
    def self.getDomainActivityLastUnixtime(domain)
        FKVStore::getOrDefaultValue("0cda77d7-1c03-4adb-9e36-655df4ff0d8d:#{domain}", "0").to_i
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
            if !RequirementsOperator::objectMeetsRequirements(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
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
        FKVStore::set("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}", "!today")
    end
    def self.todayOk(uuid)
        FKVStore::getOrNull("9e8881b5-3bf7-4a08-b454-6b8b827cd0e0:#{CommonsUtils::currentDay()}:#{uuid}").nil?
    end
    def self.transform()
        $flock["objects"] = $flock["objects"].map{|object|
            if !TodayOrNotToday::todayOk(object["uuid"]) and object["metric"]<=1 then
                # The second condition in case we start running an object that wasn't scheduled to be shown today (they can be found through search)
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
            system("open '#{metadata["url"]}'")
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
