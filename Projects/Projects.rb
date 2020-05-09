
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CoreData.rb"
=begin

    CoreDataFile::copyFileToRepository(filepath)
    CoreDataFile::filenameToFilepath(filename)
    CoreDataFile::exists?(filename)
    CoreDataFile::openOrCopyToDesktop(filename)

    CoreDataDirectory::copyFolderToRepository(folderpath)
    CoreDataDirectory::foldernameToFolderpath(foldername)
    CoreDataDirectory::openFolder(foldername)

=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Common.rb"

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTarget.rb"
=begin 
    CatalystStandardTarget::makeNewTargetInteractivelyOrNull()
    CatalystStandardTarget::targetToString(target)
    CatalystStandardTarget::openTarget(target)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Runner.rb"
=begin 
    Runner::isRunning(uuid)
    Runner::runTimeInSecondsOrNull(uuid) # null | Float
    Runner::start(uuid)
    Runner::stop(uuid) # null | Float
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Ping.rb"
=begin 
    Ping::ping(uuid, weight, validityTimespan)
    Ping::pong(uuid)
=end

# -----------------------------------------------------------------

class Projects

    # -----------------------------------------------------------
    # Projects

    # Projects::pathToProjects()
    def self.pathToProjects()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Projects/projects1"
    end

    # Projects::projects()
    def self.projects()
        Dir.entries(Projects::pathToProjects())
            .select{|filename| filename[-5, 5] == ".json" }
            .map{|filename| "#{Projects::pathToProjects()}/#{filename}" }
            .map{|filepath| JSON.parse(IO.read(filepath)) }
            .sort{|c1, c2| c1["creationtime"] <=> c2["creationtime"] }
    end

    # Projects::getAckProjects()
    def self.getAckProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "ack" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getIFCSProjectsOrderedByPosition()
    def self.getIFCSProjectsOrderedByPosition()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "ifcs" }
            .sort{|p1, p2| p1["schedule"]["position"] <=> p2["schedule"]["position"] }
    end

    # Projects::getStandardProjects()
    def self.getStandardProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "standard" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getProjectByUUIDOrNUll(uuid)
    def self.getProjectByUUIDOrNUll(uuid)
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Projects::save(project)
    def self.save(project)
        File.open("#{Projects::pathToProjects()}/#{project["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(project)) }
    end

    # Projects::destroy(project)
    def self.destroy(project)
        uuid = project["uuid"]
        return if uuid == "20200502-141331-226084" # Guardian General Work
        return if uuid == "44caf74675ceb79ba5cc13bafa102509369c2b53" # Inbox
        return if uuid == "0219fd54bd5841008b18c414a5b2dea331bad1c5" # Infinity
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # Projects::makeProject(uuid, description, schedule, items)
    def self.makeProject(uuid, description, schedule, items)
        {
            "uuid"         => uuid,
            "creationtime" => Time.new.to_f,
            "description"  => description,
            "schedule" => schedule,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, schedule, items)
    def self.issueProject(uuid, description, schedule, items)
        project = Projects::makeProject(uuid, description, schedule, items)
        Projects::save(project)
        project
    end

    # Projects::selectProjectOrNull()
    def self.selectProjectOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project:", Projects::projects(), lambda {|project| project["description"] })
    end

    # Projects::selectProjectFromExistingOrNewOrNull()
    def self.selectProjectFromExistingOrNewOrNull()

        project = Projects::selectProjectOrNull()
        return project if project

        puts "-> No project select. Please give a description to make a new one (empty for aborting operation)"
        description = LucilleCore::askQuestionAnswerAsString("description: ")

        if description == "" then
            return nil
        end

        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("project schedule type", ["standard", "ack", "ifcs"])

        puts "-> Making schedule"
        schedule = nil
        if scheduletype == "standard" then
            schedule = {
                "type"  => "standard"
            }
        end
        if scheduletype == "ack" then
            schedule = {
                "type" => "ack"
            }
        end
        if scheduletype == "ifcs" then
            schedule = {
                "type" => "ifcs",
                "position" => Projects::interactiveChoiceOfIfcsPosition()
            }
        end
        puts JSON.pretty_generate(schedule)

        Projects::issueProject(SecureRandom.uuid, description, schedule, []) # Project
    end

    # Projects::makeNewScheduleInteractiveOrNull()
    def self.makeNewScheduleInteractiveOrNull()
        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntitiesOrNull("project schedule type", ["standard", "ifcs", "ack"])
        return nil if scheduletype.nil?
        puts "-> Making schedule"
        schedule = nil
        if scheduletype == "standard" then
            schedule = {
                "type"  => "standard"
            }
        end
        if scheduletype == "ack" then
            schedule = {
                "type" => "ack"
            }
        end
        if scheduletype == "ifcs" then
            position = Projects::interactiveChoiceOfIfcsPosition()
            schedule = {
                "type" => "ifcs",
                "position" => position
            }
        end
        puts JSON.pretty_generate(schedule)
        schedule
    end

    # -----------------------------------------------------------
    # Project Time and Metric

    # Projects::setProjectAlgebraicTime(uuid, timespanInSeconds)
    def self.setProjectAlgebraicTime(uuid, timespanInSeconds)
        Ping::ping(uuid, timespanInSeconds, 86400*30) # 30 days
    end

    # Projects::getProjectAlgebraicTime(uuid)
    def self.getProjectAlgebraicTime(uuid)
        Ping::pong(uuid)
    end

    # Projects::algebraicTimeToMetric(uuid, timeInSeconds)
    def self.algebraicTimeToMetric(uuid, timeInSeconds)
        baseMetric = 0.76
        if uuid == "44caf74675ceb79ba5cc13bafa102509369c2b53" then
            return 0.77 # Not affected by the time
        end
        timeInHours = timeInSeconds.to_f/3600
        return 0.76 + Math.atan(-timeInHours).to_f/1000
    end

    # Projects::projectMetric(project)
    def self.projectMetric(project)
        uuid = project["uuid"]
        return 1 if Runner::isRunning(uuid)
        return 0 if project["schedule"]["type"] == "ack"
        if Projects::getProjectItemsByCreationTime(uuid).size > 0 then
            return 0 # We do not display a project if it has objects
        else
            Projects::algebraicTimeToMetric(uuid, Projects::getProjectAlgebraicTime(uuid))
        end
    end

    # -----------------------------------------------------------
    # Items Management

    # Projects::attachProjectItemToProject(projectuuid, item)
    def self.attachProjectItemToProject(projectuuid, item)
        # There is a copy of function in LucilleTxt/catalyst-objects-processing
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, item["uuid"], item)
    end

    # Projects::getProjectItemOrNull(projectuuid, itemuuid)
    def self.getProjectItemOrNull(projectuuid, itemuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::getProjectItemsByCreationTime(projectuuid)
    def self.getProjectItemsByCreationTime(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid)
            .sort{|i1, i2| i1["creationtime"]<=>i2["creationtime"] }
    end

    # Projects::detachProjectItemFromProject(projectuuid, itemuuid)
    def self.detachProjectItemFromProject(projectuuid, itemuuid)
        BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::projectItemToString(item)
    def self.projectItemToString(item)
        item["description"] || CatalystStandardTarget::targetToString(item["target"])
    end

    # Projects::recastItem(projectuuid, itemuuid)
    def self.recastItem(projectuuid, itemuuid)
        item = Projects::getProjectItemOrNull(projectuuid, itemuuid)
        return if item.nil?
        # We need to choose a project, possibly a new one and add the item to it and remove the item from the original project
        targetproject = Projects::selectProjectFromExistingOrNewOrNull()
        Projects::attachProjectItemToProject(targetproject["uuid"], item)
        Projects::detachProjectItemFromProject(projectuuid, itemuuid)
    end

    # -----------------------------------------------------------
    # In Flight Control System

    # Projects::getOrderedIfcsProjectsWithComputedOrdinal()
    def self.getOrderedIfcsProjectsWithComputedOrdinal() # Array[ (project, ordinal: Int) ]
        Projects::getIFCSProjectsOrderedByPosition()
            .map
            .with_index
            .to_a
    end

    # Projects::getOrdinal(uuid)
    def self.getOrdinal(uuid)
        Projects::getOrderedIfcsProjectsWithComputedOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # Projects::interactiveChoiceOfIfcsPosition()
    def self.interactiveChoiceOfIfcsPosition() # Float
        puts "Items"
        Projects::getIFCSProjectsOrderedByPosition()
            .each{|project|
                uuid = project["uuid"]
                puts "    - #{("%5.3f" % project["schedule"]["position"])} #{project["description"]}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # Projects::uuidTotalTimespanIncludingLiveRun(uuid)
    def self.uuidTotalTimespanIncludingLiveRun(uuid)
        x0 = Projects::getProjectAlgebraicTime(uuid)
        x1 = 0
        unixtime = KeyValueStore::getOrNull(nil, "db183530-293a-41f8-b260-283c59659bd5:#{uuid}")
        if unixtime then
            x1 = Time.new.to_f - unixtime.to_f
        end
        x0 + x1
    end

    # Projects::isWeekDay()
    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # Projects::getProjectsTotalAttributed24TimeExpectation()
    def self.getProjectsTotalAttributed24TimeExpectation()
        if Projects::isWeekDay() then
            2 * 3600
        else
            4 * 3600
        end
    end

    # Projects::getGuardian24TimeExpectation()
    def self.getGuardian24TimeExpectation()
        if Projects::isWeekDay() then
            5 * 3600
        else
            0 * 3600
        end
    end

    # Projects::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    def self.ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        Projects::getProjectsTotalAttributed24TimeExpectation() * (1.to_f / 2**(ordinal+1))
    end

    # Projects::getProject24HoursTimeExpectationInSeconds(uuid, ordinal)
    def self.getProject24HoursTimeExpectationInSeconds(uuid, ordinal)
        return Projects::getGuardian24TimeExpectation() if uuid == "20200502-141331-226084"
        Projects::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    end

    # Projects::distributeDayTimePenatiesIfNotDoneAlready()
    def self.distributeDayTimePenatiesIfNotDoneAlready()
        return if Time.new.hour < 9
        return if Time.new.hour > 18
        Projects::getIFCSProjectsOrderedByPosition()
            .each{|project|
                uuid = project["uuid"]
                next if Projects::getProjectAlgebraicTime(uuid) < -3600 # This values allows small targets to get some time and the big ones not to become overwelming
                next if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
                timespan = Projects::getProject24HoursTimeExpectationInSeconds(uuid, Projects::getOrdinal(uuid))
                next if timespan.nil?
                Projects::setProjectAlgebraicTime(uuid, -timespan)
                KeyValueStore::setFlagTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
            }
    end

    # -----------------------------------------------------------
    # Fsck

    # Projects::fsckItem(item)
    def self.fsckItem(item)
        puts JSON.pretty_generate(item)
        if item["uuid"].nil? then
            puts item
            raise "Project item has no uuid"
        end
        if item["creationtime"].nil? then
            puts item
            raise "Project item has no creationtime"
        end
        if item["target"].nil? then
            puts item
            raise "Project item has no target"
        end
        target = item["target"]
        CatalystStandardTarget::fsckTarget(target)
    end

    # Projects::fsckProject(project)
    def self.fsckProject(project)
        puts JSON.pretty_generate(project)
        if project["uuid"].nil? then
            puts project
            raise "Project has no uuid"
        end
        if project["creationtime"].nil? then
            puts project
            raise "Project has no creationtime"
        end
        if project["description"].nil? then
            puts project
            raise "Project has no description"
        end
        if project["schedule"].nil? then
            puts project
            raise "Project has no schedule"
        end
        items = Projects::getProjectItemsByCreationTime(project["uuid"])
        items.each{|item|
            Projects::fsckItem(item)
        }
    end

    # -----------------------------------------------------------
    # User Interface

    # Projects::projectKickerText(project)
    def self.projectKickerText(project)
        uuid = project["uuid"]
        if project["schedule"]["type"] == "standard" then
            return "[project standard ; time: #{"%7.2f" % (Projects::getProjectAlgebraicTime(uuid).to_f/3600)} hours]"
        end
        if project["schedule"]["type"] == "ifcs" then
            return "[project ifcs ; pos: #{("%6.3f" % project["schedule"]["position"])} ; ord: #{"%2d" % Projects::getOrdinal(uuid)} ; time: #{"%5.2f" % (Projects::getProjectAlgebraicTime(uuid).to_f/3600)}]"
        end
        if project["schedule"]["type"] == "ack" then
            return ""
        end
        raise "Projects: f40a0f00"
    end

    # Projects::projectSuffixText(project)
    def self.projectSuffixText(project)
        uuid = project["uuid"]
        str1 = " (#{Projects::getProjectItemsByCreationTime(project["uuid"]).size})"
        str2 = 
            if Runner::isRunning(uuid) then
                " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hours)"
            else
                ""
            end
        "#{str1}#{str2}"
    end

    # Projects::projectToString(project)
    def self.projectToString(project)
        "#{Projects::projectKickerText(project)} #{project["description"]}#{Projects::projectSuffixText(project)}"
    end

    # Projects::diveProject(project)
    def self.diveProject(project)
        loop {
            system("clear")
            puts "project: #{Projects::projectToString(project)}"
            puts "uuid: #{project["uuid"]}"
            puts "description: #{project["description"]}"
            puts "schedule: #{project["schedule"]}"
            options = [
                "start",
                "dive items",
                "set description",
                "recast"
            ]
            if project["schedule"]["type"] == "ifcs" then
                options << "set ifcs position"
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "start" then
                Runner::start(project["uuid"])
            end
            if option == "dive items" then
                items = Projects::getProjectItemsByCreationTime(project["uuid"])
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Projects::projectItemToString(item) })
                next if item.nil?
                Projects::diveItem(project, item)
            end
            if option == "set description" then
                project["description"] = CatalystCommon::editTextUsingTextmate(project["description"])
                Projects::save(project)
            end
            if option == "set ifcs position" then
                puts "--------------------"
                Projects::getIFCSProjectsOrderedByPosition()
                    .each{|project|
                        puts Projects::projectToString(project)
                    }
                puts "--------------------"
                position = LucilleCore::askQuestionAnswerAsString("position: ").to_f
                project["schedule"]["position"] = position
                Projects::save(project)
            end
            if option == "recast" then
                schedule = Projects::makeNewScheduleInteractiveOrNull()
                next if schedule.nil?
                project["schedule"] = schedule
                Projects::save(project)
            end
        }
    end

    # Projects::diveItem(project, item)
    def self.diveItem(project, item)
        loop {
            system("clear")
            puts "project item: #{Projects::projectItemToString(item)}"
            puts "uuid: #{item["uuid"]}"
            puts "description: #{item["description"]}"
            puts "target: #{item["target"]}"
            options = [
                "open",
                "done",
                "set description"
            ]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "open" then
                CatalystStandardTarget::openTarget(item["target"])
            end
            if option == "done" then
                Projects::detachProjectItemFromProject(project["uuid"], item["uuid"])
            end
            if option == "set description" then
                item["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
                Projects::attachProjectItemToProject(project["uuid"], item)
            end
        }
    end
end



