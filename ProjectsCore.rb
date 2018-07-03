
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
        TimeStructuresOperator::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
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
    # Time Struture (2)
    # ProjectsCore::liveRatioDoneOrNull(projectuuid)

    def self.getTimeStructureAskIfAbsent(projectuuid)
        timestructure = TimeStructuresOperator::getTimeStructureOrNull(projectuuid)
        if timestructure.nil? then
            puts "Setting Time Structure for project '#{ProjectsCore::projectUUID2NameOrNull(projectuuid)}'"
            timeUnitInDays = LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f
            timeCommitmentInHours = LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f
            timestructure = TimeStructuresOperator::setTimeStructure(projectuuid, timeUnitInDays, timeCommitmentInHours)
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
            if timestructure["time-commitment-in-hours"]>0 and timestructure["time-unit-in-days"]>0 then
                MetricsOfTimeStructures::metric(projectuuid, 0.2, 0.750, timestructure)
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
    # ProjectsCore::projectToString(projectuuid)
    # ProjectsCore::interactivelySelectProjectUUIDOrNUll(): projectuuid: String
    # ProjectsCore::ui_projectsDive()
    # ProjectsCore::ui_projectDive(projectuuid)
    # ProjectsCore::deleteProject2(projectuuid)

    def self.ui_projectTimeStructureAsStringContantLength(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        if timestructure["time-commitment-in-hours"]==0 then
            return "                      "
        end
        # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }
        "#{"%5.2f" % timestructure["time-commitment-in-hours"]} hours, #{"%4.2f" % (timestructure["time-unit-in-days"])} days"
    end

    def self.projectToString(projectuuid)
        "#{ProjectsCore::ui_projectTimeStructureAsStringContantLength(projectuuid)} | #{ProjectsCore::liveRatioDoneOrNull(projectuuid) ? ("%6.2f" % (100*[ProjectsCore::liveRatioDoneOrNull(projectuuid), 9.99].min)) + " %" : "        "} | #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
    end

    def self.ui_projectDive(projectuuid)
        puts "-> #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
        puts ProjectsCore::projectToString(projectuuid)
        loop {
            menuItem3 = "operation : start"  
            menuItem4 = "operation : set time structure"             
            menuItem5 = "operation : add time"
            menu = [ menuItem3, menuItem4, menuItem5 ]
            menuChoice = LucilleCore::selectEntityFromListOfEntitiesOrNull("menu", menu)
            break if menuChoice.nil?
            if menuChoice == menuItem3 then
                Chronos::start(projectuuid)
                return
            end
            if menuChoice == menuItem4 then
                TimeStructuresOperator::setTimeStructure(
                        projectuuid, 
                        LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f, 
                        LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f)
                next
            end
            if menuChoice == menuItem5 then
                hours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                Chronos::addTimeInSeconds(projectuuid, hours*3600)
                next
            end
        }
    end

    def self.ui_projectsDive()
        loop {
            projectuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull(
                "projects", 
                ProjectsCore::projectsUUIDs().sort{|projectuuid1, projectuuid2| ProjectsCore::metric(projectuuid1) <=> ProjectsCore::metric(projectuuid2) }.reverse, 
                lambda{ |projectuuid| ProjectsCore::projectToString(projectuuid) })
            break if projectuuid.nil?
            ProjectsCore::ui_projectDive(projectuuid)
        }
    end

    def self.interactivelySelectProjectUUIDOrNUll()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

end