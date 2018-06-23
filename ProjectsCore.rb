
# encoding: UTF-8

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

# -------------------------------------------------------------

class ProjectsCore

    # ---------------------------------------------------
    # ProjectsCore::projectsUUIDs()
    # ProjectsCore::fs_uuid2locationOrNull(uuid)

    def self.fs_locations()
        Dir.entries("/Galaxy/Projects")
            .select{|filename| (filename[0,1] != ".") and (filename != 'Icon'+["0D"].pack("H*")) }
            .map{|filename| "/Galaxy/Projects/#{filename}" }
    end

    def self.fs_location2UUID(location)
        uuidfilepath = "#{location}/.uuid"
        if !File.exists?(uuidfilepath) then
            File.open(uuidfilepath, "w"){|f| f.write(SecureRandom.hex(4)) }
        end
        IO.read(uuidfilepath).strip
    end

    def self.fs_uuid2locationOrNull(uuid)
        ProjectsCore::fs_locations()
            .each{|location|
                if ProjectsCore::fs_location2UUID(location)==uuid then
                    return location
                end
            }
        nil
    end

    def self.fs_uuids()
        ProjectsCore::fs_locations().map{|location| ProjectsCore::fs_location2UUID(location) }
    end 
    
    def self.projectsUUIDs()
        ProjectsCore::fs_uuids()
    end

    # ProjectsCore::createNewProject(projectname, timeUnitInDays, timeCommitmentInHours)
    # ProjectsCore::projectUUID2NameOrNull(projectuuid)

    def self.createNewProject(projectname, timeUnitInDays, timeCommitmentInHours)
        projectuuid = SecureRandom.hex(4)
        FileUtils.mkpath("/Galaxy/Projects/#{projectname}")
        File.open("/Galaxy/Projects/#{projectname}/.uuid", "w"){|f| f.write(projectuuid) }
        ProjectsCore::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
        projectuuid
    end

    def self.projectUUID2NameOrNull(projectuuid)
        ProjectsCore::fs_locations()
            .select{|location| projectuuid == ProjectsCore::fs_location2UUID(location) }
            .each{|location|
                return File.basename(location)
            }
        nil
    end

    # ---------------------------------------------------
    # ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
    # ProjectsCore::addObjectUUIDToProjectInteractivelyChosen(objectuuid, projectuuid)
    # ProjectsCore::projectCatalystObjectUUIDs(projectuuid))

    def self.addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        uuids = ( ProjectsCore::projectCatalystObjectUUIDs(projectuuid) + [objectuuid] ).uniq
        FKVStore::set("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", JSON.generate(uuids))
    end

    def self.addObjectUUIDToProjectInteractivelyChosen(objectuuid)
        projectuuid = ProjectsCore::interactivelySelectProjectUUIDOrNUll()
        if projectuuid.nil? then
            if LucilleCore::interactivelyAskAYesNoQuestionResultAsBoolean("Would you like to create a new project ? ") then
                projectname = LucilleCore::askQuestionAnswerAsString("project name: ")
                projectuuid = ProjectsCore::createNewProject(projectname, LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f, LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f)
            else
                return
            end
        end
        ProjectsCore::addCatalystObjectUUIDToProject(objectuuid, projectuuid)
        projectuuid
    end

    def self.projectCatalystObjectUUIDs(projectuuid)
        JSON.parse(FKVStore::getOrDefaultValue("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", "[]"))
            .select{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
    end

    def self.projectCatalystObjects(projectuuid)
        JSON.parse(FKVStore::getOrDefaultValue("C613EA19-5BC1-4ECB-A5B5-BF5F6530C05D:#{projectuuid}", "[]"))
            .map{|objectuuid| TheFlock::getObjectByUUIDOrNull(objectuuid) }
            .compact
    end

    # ---------------------------------------------------
    # ProjectsCore::projectFileSystemFilenames(projectuuid)

    def self.projectFileSystemFilenames(projectuuid)
        location = ProjectsCore::fs_uuid2locationOrNull(projectuuid)
        return [] if location.nil?
        return Dir.entries(location)
            .select{|filename| (filename[0,1] != ".") and (filename != 'Icon'+["0D"].pack("H*")) }
    end

    # ---------------------------------------------------
    # Time Struture (2)
    # The time structure against projects
    # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }

    # ProjectsCore::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
    # ProjectsCore::liveRatioDoneOrNull(projectuuid)

    def self.setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
        timestructure = { "time-unit-in-days"=> timeUnitInDays, "time-commitment-in-hours" => timeCommitmentInHours }
        FKVStore::set("02D6DCBC-87BD-4D4D-8F0B-411B7C06B972:#{projectuuid}", JSON.generate(timestructure))
        timestructure
    end

    def self.getTimeStructureOrNull(projectuuid)
        timestructure = FKVStore::getOrNull("02D6DCBC-87BD-4D4D-8F0B-411B7C06B972:#{projectuuid}")
        return nil if timestructure.nil?
        JSON.parse(timestructure)
    end

    def self.getTimeStructureAskIfAbsent(projectuuid)
        timestructure = ProjectsCore::getTimeStructureOrNull(projectuuid)
        if timestructure.nil? then
            puts "Setting Time Structure for project '#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}'"
            timeUnitInDays = LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f
            timestructure = ProjectsCore::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
        end
        timestructure
    end

    def self.liveRatioDoneOrNull(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        return nil if timestructure["time-commitment-in-hours"]==0
        (Chronos::summedTimespansWithDecayInSecondsLiveValue(projectuuid, timestructure["time-unit-in-days"]).to_f/3600).to_f/timestructure["time-commitment-in-hours"]
    end

    def self.metric(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        # { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }
        metric = 
            if timestructure["time-commitment-in-hours"] > 0 then
                    Chronos::metric3(projectuuid, 0.2, 0.750, timestructure["time-unit-in-days"], timestructure["time-commitment-in-hours"])
            else
                    0.1
            end
        if Chronos::isRunning(projectuuid) then
            metric = [metric, 0.2].max
        end
        metric + CommonsUtils::traceToMetricShift(projectuuid)
    end

    def self.averageDailyCommitmentInHours()
        ProjectsCore::projectsUUIDs()
        .map{|projectuuid|
            timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
            time = timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]
        }
        .inject(0, :+)
    end

    # ---------------------------------------------------
    # ProjectsCore::transform(objects)

    def self.transform(objects)
        uuids = ProjectsCore::projectsUUIDs()
            .map{|projectuuid| ProjectsCore::projectCatalystObjectUUIDs(projectuuid) }
            .flatten
        objects.map{|object|
            if uuids.include?(object["uuid"]) then
                object["metric"] = 0
            end
            object
        }
    end

    # ---------------------------------------------------
    # ProjectsCore::projectToString(projectuuid)
    # ProjectsCore::interactivelySelectProjectUUIDOrNUll()
    # ProjectsCore::ui_projectsDive()
    # ProjectsCore::ui_projectDive(projectuuid)
    # ProjectsCore::deleteProject2(projectuuid)

    def self.ui_projectTimeStructureAsStringContantLength(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        if timestructure["time-commitment-in-hours"]==0 then
            return "                     "
        end
        # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }
        "#{"%4.2f" % timestructure["time-commitment-in-hours"]} hours, #{"%4.2f" % (timestructure["time-unit-in-days"])} days"
    end

    def self.projectToString(projectuuid)
        catalystObjectsFragment = (ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size>0 ? "#{ProjectsCore::projectCatalystObjectUUIDs(projectuuid).size} c" : "").rjust(4)
        fsObjectsFragment = (ProjectsCore::projectFileSystemFilenames(projectuuid).size>0 ? "#{ProjectsCore::projectFileSystemFilenames(projectuuid).size} fs" :      "").rjust(5)
        "#{ProjectsCore::ui_projectTimeStructureAsStringContantLength(projectuuid)} | #{ProjectsCore::liveRatioDoneOrNull(projectuuid) ? ("%6.2f" % (100*[ProjectsCore::liveRatioDoneOrNull(projectuuid), 9.99].min)) + " %" : "        "} | #{catalystObjectsFragment}, #{fsObjectsFragment} | #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
    end

    def self.ui_projectDive(projectuuid)
        puts "-> #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
        puts ProjectsCore::projectToString(projectuuid)
        loop {
            catalystobjects = ProjectsCore::projectCatalystObjectUUIDs(projectuuid)
                .map{|objectuuid| TheFlock::flockObjects().select{|object| object["uuid"]==objectuuid }.first }
                .compact
                .sort{|o1,o2| o1['metric']<=>o2['metric'] }
                .reverse
            menuItem3 = "operation : start"  
            menuItem4 = "operation : set time structure"             
            menuItem5 = "operation : add time"
            menuStringsOrCatalystObjects = catalystobjects
            menuStringsOrCatalystObjects = menuStringsOrCatalystObjects + [ menuItem3, menuItem4, menuItem5 ]
            toStringLambda = lambda{ |menuStringOrCatalystObject|
                # Here item is either one of the strings or an object
                # We return either a string or one of the objects
                if menuStringOrCatalystObject.class.to_s == "String" then
                    string = menuStringOrCatalystObject
                    string
                else
                    object = menuStringOrCatalystObject
                    "object    : #{CommonsUtils::object2Line_v0(object)}"
                end
            }
            menuChoice = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("menu", menuStringsOrCatalystObjects, toStringLambda)
            break if menuChoice.nil?
            if menuChoice == menuItem3 then
                Chronos::start(projectuuid)
                return
            end
            if menuChoice == menuItem4 then
                ProjectsCore::setTimeStructure(
                        projectuuid, 
                        LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f, 
                        LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f)
                next
            end
            if menuChoice == menuItem4 then
                hours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                Chronos::addTimeInSeconds(projectuuid, hours*3600)
            end
            # By now, menuChoice is a catalyst object
            object = menuChoice
            CommonsUtils::doPresentObjectInviteAndExecuteCommand(object)
        }
    end

    def self.ui_projectsDive()
        loop {
            projectuuid = LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull(
                "projects", 
                ProjectsCore::projectsUUIDs().sort{|projectuuid1, projectuuid2| ProjectsCore::metric(projectuuid1) <=> ProjectsCore::metric(projectuuid2) }.reverse, 
                lambda{ |projectuuid| ProjectsCore::projectToString(projectuuid) })
            break if projectuuid.nil?
            ProjectsCore::ui_projectDive(projectuuid)
        }
    end

    def self.interactivelySelectProjectUUIDOrNUll()
        LucilleCore::interactivelySelectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

end