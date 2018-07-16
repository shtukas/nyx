
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

    # ---------------------------------------------------
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
    # Time Struture

    # ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
    # ProjectsCore::updateLocalTimeStructures()
    # ProjectsCore::localTimeStructuresDataFiles()
    # ProjectsCore::updateTodayCommonTimeBySeconds(timespanInSeconds)
    # ProjectsCore::getCummulatedTodayCommonTimeInSeconds()
    # ProjectsCore::projectsTimes() # [averageDailyCommitmentInHours, doneInHours, percentageDone]
    # ProjectsCore::addTimeInSecondsToProject(projectuuid, timeInSeconds)
    # ProjectsCore::getLocalTimeStructureDataFileForProjectOrNull(projectuuid)
    # ProjectsCore::addTimeInSecondsToProjectLocalCommitmentItem(itemuuid, projectuuid, timeInSeconds)

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

    def self.averageDailyCommitmentInHours()
        ProjectsCore::projectsUUIDs()
        .map{|projectuuid|
            timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
            time = timestructure["time-commitment-in-hours"].to_f/timestructure["time-unit-in-days"]
        }
        .inject(0, :+)
    end

    def self.updateLocalTimeStructures()
        ProjectsCore::projectsUUIDs()
            .each{|projectuuid|
                location = ProjectsCore::fs_uuid2locationOrNull(projectuuid)
                filepath = "#{location}/local-time-structure.json"
                next if !File.exists?(filepath)
                data = JSON.parse(IO.read(filepath))
                data["projectuuid"] = projectuuid
                data["reference-time-structure"] = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
                File.open(filepath, "w"){ |f| f.puts(JSON.pretty_generate(data)) }
            }
    end

    def self.getLocalTimeStructureDataFileForProjectOrNull(projectuuid)
        location = ProjectsCore::fs_uuid2locationOrNull(projectuuid)
        return nil if location.nil?
        filepath = "#{location}/local-time-structure.json"
        data = 
            if File.exists?(filepath) then
                JSON.parse(IO.read(filepath))
            else
                timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
                data = {}
                data["projectuuid"] = projectuuid
                data["reference-time-structure"] = timestructure
                data["local-commitments"] = []
                File.open(filepath, "w"){ |f| f.puts(JSON.pretty_generate(data)) }
                data
            end
        complementaryTimeShare = 1 - [ data["local-commitments"].map{|i| i["timeshare"] }.inject(0, :+) , 1 ].min   
        data["local-commitments"] << { "uuid" => Digest::SHA1.hexdigest("26eef7d1-9b1f-4687-b75b-a35d68ab31fd/#{projectuuid}")[0,8], "description" => "(main)", "timeshare" => complementaryTimeShare }
        data
    end

    def self.localTimeStructuresDataFiles()
        ProjectsCore::projectsUUIDs()
            .map{|projectuuid| ProjectsCore::getLocalTimeStructureDataFileForProjectOrNull(projectuuid) }
            .compact
    end

    def self.updateTodayCommonTimeBySeconds(timespanInSeconds)
        MiniFIFOQ::push("80077ab5-fcc1-4d54-a88b-3d3666e00782:#{CommonsUtils::currentDay()}", timespanInSeconds)
    end

    def self.getCummulatedTodayCommonTimeInSeconds()
        MiniFIFOQ::values("80077ab5-fcc1-4d54-a88b-3d3666e00782:#{CommonsUtils::currentDay()}").compact.inject(0, :+)
    end

    def self.projectsTimes() # [averageDailyCommitmentInHours, doneInHours, percentageDone]
        averageDailyCommitmentInHours = ProjectsCore::averageDailyCommitmentInHours()
        doneInHours = ProjectsCore::getCummulatedTodayCommonTimeInSeconds().to_f/3600
        percentageDone = (100*doneInHours).to_f/averageDailyCommitmentInHours
        [averageDailyCommitmentInHours, doneInHours, percentageDone]
    end

    def self.addTimeInSecondsToProject(projectuuid, timeInSeconds)
        Chronos::addTimeInSeconds(projectuuid, timeInSeconds)
        ProjectsCore::updateTodayCommonTimeBySeconds(timeInSeconds)
    end

    def self.addTimeInSecondsToProjectLocalCommitmentItem(itemuuid, projectuuid, timeInSeconds)
        Chronos::addTimeInSeconds(itemuuid, timeInSeconds)
        Chronos::addTimeInSeconds(projectuuid, timeInSeconds)
        ProjectsCore::updateTodayCommonTimeBySeconds(timeInSeconds)
    end

    # ---------------------------------------------------
    # ProjectsCore::ui_projectToString(projectuuid)
    # ProjectsCore::ui_interactivelySelectProjectUUIDOrNUll(): projectuuid: String
    # ProjectsCore::ui_projectsDive()
    # ProjectsCore::ui_projectDive(projectuuid)
    # ProjectsCore::deleteProject2(projectuuid)
    # ProjectsCore::ui_interactivelySelectProjectLocalCommitmentItemOrNUll(projectuuid)
    # ProjectsCore::ui_donateTimeSpanInSecondsToProjectLocalCommitmentItem(timeSpanInSeconds)

    def self.ui_projectTimeStructureAsStringContantLength(projectuuid)
        timestructure = ProjectsCore::getTimeStructureAskIfAbsent(projectuuid)
        if timestructure["time-commitment-in-hours"]==0 then
            return "                      "
        end
        # TimeStructure: { "time-unit-in-days"=> Float, "time-commitment-in-hours" => Float }
        "#{"%5.2f" % timestructure["time-commitment-in-hours"]} hours, #{"%4.2f" % (timestructure["time-unit-in-days"])} days"
    end

    def self.ui_projectToString(projectuuid)
        "#{ProjectsCore::ui_projectTimeStructureAsStringContantLength(projectuuid)} | #{TimeStructuresOperator::projectLiveRatioDoneOrNull(projectuuid) ? ("%6.2f" % (100*[TimeStructuresOperator::projectLiveRatioDoneOrNull(projectuuid), 9.99].min)) + " %" : "        "} | #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
    end

    def self.ui_projectDive(projectuuid)
        puts "-> #{ProjectsCore::projectUUID2NameOrNull(projectuuid)}"
        puts "    -> #{ProjectsCore::ui_projectToString(projectuuid)}"
        puts "distribution:"
        ProjectsCore::getLocalTimeStructureDataFileForProjectOrNull(projectuuid)["local-commitments"].each{|item|
            # {
            #   "uuid": "D4181B7A",
            #   "description": "04-react-from-zero",
            #   "timeshare": 0.2
            # }
            puts "    - #{ProjectsCore::projectUUID2NameOrNull(projectuuid)} / #{item["description"]} ( time share: #{item["timeshare"].round(2)} )"
        }
        loop {
            menuChoice = LucilleCore::selectEntityFromListOfEntitiesOrNull("menu", [ "operation : set time structure", "operation : start", "operation : add time" ])
            break if menuChoice.nil?
            if menuChoice == "operation : set time structure" then
                TimeStructuresOperator::setTimeStructure(
                        projectuuid, 
                        LucilleCore::askQuestionAnswerAsString("Time unit in days: ").to_f, 
                        LucilleCore::askQuestionAnswerAsString("Time commitment in hours: ").to_f)
                next
            end
            if menuChoice == "operation : start" then
                item = ProjectsCore::ui_interactivelySelectProjectLocalCommitmentItemOrNUll(projectuuid)
                Chronos::start(item["uuid"])
                return
            end
            if menuChoice == "operation : add time" then
                item = ProjectsCore::ui_interactivelySelectProjectLocalCommitmentItemOrNUll(projectuuid)
                hours = LucilleCore::askQuestionAnswerAsString("Time in hours: ").to_f
                Chronos::addTimeInSeconds(item["uuid"], hours*3600)
                ProjectsCore::addTimeInSecondsToProject(projectuuid, hours*3600)
                next
            end
        }
    end

    def self.ui_projectsDive()
        loop {
            projectuuid = LucilleCore::selectEntityFromListOfEntitiesOrNull(
                "projects", 
                ProjectsCore::projectsUUIDs(), 
                lambda{ |projectuuid| ProjectsCore::ui_projectToString(projectuuid) })
            break if projectuuid.nil?
            ProjectsCore::ui_projectDive(projectuuid)
        }
    end

    def self.ui_interactivelySelectProjectUUIDOrNUll()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", ProjectsCore::projectsUUIDs(), lambda{ |projectuuid| ProjectsCore::projectUUID2NameOrNull(projectuuid) })
    end

    def self.ui_interactivelySelectProjectLocalCommitmentItemOrNUll(projectuuid) # { "uuid": "1D189B32", "description": "01-Frontend Padawan", "timeshare": 0.2 }
        localdata = ProjectsCore::getLocalTimeStructureDataFileForProjectOrNull(projectuuid)
        return nil if localdata.nil?
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", localdata["local-commitments"], lambda{ |item| item["description"] })
    end

    def self.ui_donateTimeSpanInSecondsToProjectLocalCommitmentItem(timeSpanInSeconds)
        projectuuid = ProjectsCore::ui_interactivelySelectProjectUUIDOrNUll()
        return if projectuuid.nil?        
        localCommitmentItem = ProjectsCore::ui_interactivelySelectProjectLocalCommitmentItemOrNUll(projectuuid)
        return if localCommitmentItem.nil?
        ProjectsCore::addTimeInSecondsToProjectLocalCommitmentItem(localCommitmentItem["uuid"], projectuuid, timeSpanInSeconds)
    end

end