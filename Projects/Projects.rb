
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
    # Misc

    # Projects::pingRetainPeriodInSeconds()
    def self.pingRetainPeriodInSeconds()
        (365.24/4)*86400 # Number of seconds in a quarter of a year
    end

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

    # Projects::getStandardProjects()
    def self.getStandardProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "standard" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getAckProjects()
    def self.getAckProjects()
        Projects::projects()
            .select{|project| project["schedule"]["type"] == "ack" }
            .sort{|p1, p2| p1["creationtime"] <=> p2["creationtime"] }
    end

    # Projects::getProjectByUUIDOrNUll(uuid)
    def self.getProjectByUUIDOrNUll(uuid)
        filepath = "#{Projects::pathToProjects()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # Projects::saveProject(project)
    def self.saveProject(project)
        File.open("#{Projects::pathToProjects()}/#{project["uuid"]}.json", "w"){|f| f.puts(JSON.pretty_generate(project)) }
    end

    # Projects::destroyProject(project)
    def self.destroyProject(project)
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
            "schedule"     => schedule,
            "items"        => items
        }
    end

    # Projects::issueProject(uuid, description, schedule, items)
    def self.issueProject(uuid, description, schedule, items)
        project = Projects::makeProject(uuid, description, schedule, items)
        Projects::saveProject(project)
        project
    end

    # Projects::selectProjectInteractivelyOrNull()
    def self.selectProjectInteractivelyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("project", Projects::projects().sort{|p1, p2| p1["description"] <=> p2["description"] }, lambda {|project| Projects::projectToString(project) })
    end

    # Projects::selectProjectFromExistingOrNewOrNull()
    def self.selectProjectFromExistingOrNewOrNull()

        project = Projects::selectProjectInteractivelyOrNull()
        return project if project

        puts "-> No project select. Please give a description to make a new one (empty for aborting operation)"
        description = LucilleCore::askQuestionAnswerAsString("description: ")

        if description == "" then
            return nil
        end

        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntities_EnsureChoice("project schedule type", ["standard", "ack"])

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
        puts JSON.pretty_generate(schedule)

        Projects::issueProject(SecureRandom.uuid, description, schedule, []) # Project
    end

    # Projects::makeNewScheduleInteractiveOrNull()
    def self.makeNewScheduleInteractiveOrNull()
        puts "-> Choosing project schedule type"
        scheduletype = LucilleCore::selectEntityFromListOfEntitiesOrNull("project schedule type", ["standard", "ack"])
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
        puts JSON.pretty_generate(schedule)
        schedule
    end

    # Projects::openProject(project)
    def self.openProject(project)
        items = Projects::getItemsByCreationTime(project["uuid"])
        if items.size == 1 then
            Projects::openItem(items[0])
            return
        end
        item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Projects::itemBestDescription(item) })
        return if item.nil?
        Projects::openItem(item)
    end

    # -----------------------------------------------------------
    # Project Items

    # Projects::attachItemToProject(projectuuid, item)
    def self.attachItemToProject(projectuuid, item)
        # There is a copy of function in LucilleTxt/catalyst-objects-processing
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, item["uuid"], item)
    end

    # Projects::getItemOrNull(projectuuid, itemuuid)
    def self.getItemOrNull(projectuuid, itemuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::getItemsByCreationTime(projectuuid)
    def self.getItemsByCreationTime(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid)
            .sort{|i1, i2| i1["creationtime"]<=>i2["creationtime"] }
    end

    # Projects::detachItemFromProject(projectuuid, itemuuid)
    def self.detachItemFromProject(projectuuid, itemuuid)
        BTreeSets::destroy("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/items1", projectuuid, itemuuid)
    end

    # Projects::itemBestDescription(item)
    def self.itemBestDescription(item)
        item["description"] || CatalystStandardTarget::targetToString(item["target"])
    end

    # Projects::recastItem(projectuuid, itemuuid)
    def self.recastItem(projectuuid, itemuuid)
        item = Projects::getItemOrNull(projectuuid, itemuuid)
        return if item.nil?
        # We need to choose a project, possibly a new one and add the item to it and remove the item from the original project
        targetproject = Projects::selectProjectFromExistingOrNewOrNull()
        return if targetproject.nil?
        Projects::attachItemToProject(targetproject["uuid"], item)
        Projects::detachItemFromProject(projectuuid, itemuuid)
    end

    # Projects::openItem(item)
    def self.openItem(item)
        CatalystStandardTarget::openTarget(item["target"])
    end

    # -----------------------------------------------------------
    # In Flight Control System Claims

    # Projects::saveIfcsClaim(claim)
    def self.saveIfcsClaim(claim)
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claim["uuid"], claim)
    end

    # Projects::issueIfcsClaimTypeProject(projectuuid, position)
    def self.issueIfcsClaimTypeProject(projectuuid, position)
        claim = {
            "uuid"        => SecureRandom.uuid,
            "type"        => "project",
            "projectuuid" => projectuuid,
            "position"    => position,
        }
        BTreeSets::set("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claim["uuid"], claim)
    end

    # Projects::issueIfcsClaimTypeItem(projectuuid, itemuuid, position)
    def self.issueIfcsClaimTypeItem(projectuuid, itemuuid, position)
        claim = {
            "uuid"        => SecureRandom.uuid,
            "type"        => "item",
            "projectuuid" => projectuuid,
            "itemuuid"    => itemuuid,
            "position"    => position
        }
        Projects::saveIfcsClaim(claim)
    end

    # Projects::getClaimByUuidOrNull(claimuuid)
    def self.getClaimByUuidOrNull(claimuuid)
        BTreeSets::getOrNull("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3", claimuuid)
    end

    # Projects::ifcsClaimDescription(claim)
    def self.ifcsClaimDescription(claim)
        if claim["type"] == "project" then
            project = Projects::getProjectByUUIDOrNUll(claim["projectuuid"])
            return ( project ? "[project] #{project["description"]}" : "{unknown project at claim/project #{claim["uuid"]}}" )
        end
        if claim["type"] == "item" then
            project = Projects::getProjectByUUIDOrNUll(claim["projectuuid"])
            if project.nil? then
                return "{unknown project at claim/item #{claim["uuid"]}}"
            end
            item = Projects::getItemOrNull(claim["projectuuid"], claim["itemuuid"])
            if item.nil? then
                return "{unknown item at claim/item #{claim["uuid"]}}"
            end
            return "[item] #{Projects::itemBestDescription(item)}"
        end
        raise "error: 0f7a2c14-5443"
    end

    # Projects::ifcsClaimsOrdered() # Array[ (ifcs claim, ordinal: Int) ]
    def self.ifcsClaimsOrdered()
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
            .sort{|c1, c2| c1["position"] <=> c2["position"] }
    end

    # Projects::ifcsClaimsOrderedWithOrdinal() # Array[ (ifcs claim, ordinal: Int) ]
    def self.ifcsClaimsOrderedWithOrdinal()
        Projects::ifcsClaimsOrdered()
            .map
            .with_index
            .to_a
    end

    # Projects::getIfcsClaimsOfTypeItemByUuids(projectuuid, itemuuid)
    def self.getIfcsClaimsOfTypeItemByUuids(projectuuid, itemuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
            .select{|claim| claim["projectuuid"] == projectuuid }
            .select{|claim| claim["itemuuid"] == itemuuid }
    end

    # Projects::getIfcsClaimsOfTypeProjectByUuid(projectuuid)
    def self.getIfcsClaimsOfTypeProjectByUuid(projectuuid)
        BTreeSets::values("/Users/pascal/Galaxy/DataBank/Catalyst/Projects/ifcs-claims", "236EA361-84E5-4DC3-9077-20D173DC73A3")
            .select{|claim| claim["projectuuid"] == projectuuid }
    end

    # Presents the current priority list of the caller and let them enter a number that is then returned
    # Projects::interactiveChoiceOfIfcsPosition()
    def self.interactiveChoiceOfIfcsPosition() # Float
        puts "Items"
        Projects::ifcsClaimsOrdered()
            .each{|claim|
                uuid = claim["uuid"]
                puts "    - #{("%5.3f" % claim["position"])} #{Projects::ifcsClaimDescription(claim)}"
            }
        LucilleCore::askQuestionAnswerAsString("position: ").to_f
    end

    # Projects::nextIfcsPosition()
    def self.nextIfcsPosition()
        Projects::ifcsClaimsOrdered().map{|claim| claim["position"] }.max.ceil
    end

    # -----------------------------------------------------------
    # In Flight Control System Daily Time Penalties

    # Projects::getOrdinalOrNull(uuid)
    def self.getOrdinalOrNull(uuid)
        Projects::ifcsClaimsOrderedWithOrdinal()
            .select{|pair| pair[0]["uuid"] == uuid }
            .map{|pair| pair[1] }
            .first
    end

    # Projects::isWeekDay()
    def self.isWeekDay()
        [1,2,3,4,5].include?(Time.new.wday)
    end

    # Projects::getTotalAttributed24TimeExpectation1()
    def self.getTotalAttributed24TimeExpectation1()
        # This is the time given to IFCS and then we move to standard projects
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
            2 * 3600
        end
    end

    # Projects::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    def self.ordinalTo24HoursTimeExpectationInSeconds(ordinal)
        Projects::getTotalAttributed24TimeExpectation1() * (1.to_f / 2**(ordinal+1))
    end

    # Projects::getProject24HoursTimeExpectationInSeconds(uuid, ordinal)
    def self.getProject24HoursTimeExpectationInSeconds(uuid, ordinal)
        return Projects::getGuardian24TimeExpectation() if uuid == "20200502-141331-226084"
        Projects::ordinalTo24HoursTimeExpectationInSeconds(ordinal)
    end

    # Projects::distributeIfcsPenatiesIfNotDoneAlready()
    def self.distributeIfcsPenatiesIfNotDoneAlready()
        return if Time.new.hour < 9
        return if Time.new.hour > 18
        Projects::ifcsClaimsOrdered()
            .each{|claim|
                uuid = claim["uuid"]
                next if Ping::pong(uuid) < -3600 # This values allows small targets to get some time and the big ones not to become overwelming
                next if KeyValueStore::flagIsTrue(nil, "2f6255ce-e877-4122-817b-b657c2b0eb29:#{uuid}:#{Time.new.to_s[0, 10]}")
                timespan = Projects::getProject24HoursTimeExpectationInSeconds(uuid, Projects::getOrdinalOrNull(uuid))
                next if timespan.nil?
                Ping::ping(uuid, -timespan, Projects::pingRetainPeriodInSeconds())
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
        items = Projects::getItemsByCreationTime(project["uuid"])
        items.each{|item|
            Projects::fsckItem(item)
        }
    end

    # -----------------------------------------------------------
    # User Interface

    # Projects::projectKickerText(project)
    def self.projectKickerText(project)
        uuid = project["uuid"]
        "[project #{project["schedule"]["type"].rjust(8)}] (#{"%7.2f" % (Ping::pong(uuid).to_f/3600)} hours)"
    end

    # Projects::projectSuffixText(project)
    def self.projectSuffixText(project)
        uuid = project["uuid"]
        str1 = " (#{Projects::getItemsByCreationTime(project["uuid"]).size})"
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

    # Projects::itemToString(project, item)
    def self.itemToString(project, item)
        itemuuid = item["uuid"]
        isRunning = Runner::isRunning(itemuuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(itemuuid).to_f/3600).round(2)} hour)" : ""
        "[item] (#{"%7.2f" % (Ping::pong(itemuuid).to_f/3600).round(2)} hours) [#{project["description"].yellow}] [#{item["target"]["type"]}] #{Projects::itemBestDescription(item)}#{runningSuffix}"
    end

    # Projects::ifcsClaimToString(claim)
    def self.ifcsClaimToString(claim)
        uuid = claim["uuid"]
        isRunning = Runner::isRunning(uuid)
        runningSuffix = isRunning ? " (running for #{(Runner::runTimeInSecondsOrNull(uuid).to_f/3600).round(2)} hour)" : ""
        "[ifcs: #{"%6.2f" % claim["position"]}] (#{"%7.2f" % (Ping::pong(uuid).to_f/3600).round(2)} hours) #{Projects::ifcsClaimDescription(claim)}#{runningSuffix}"
    end

    # Projects::diveProject(project)
    def self.diveProject(project)
        loop {
            system("clear")
            puts Projects::projectToString(project).green
            puts JSON.pretty_generate(project)
            options = [
                "dive items",
                "set description",
                "recast",
                "dive ifcs claims"
            ]
            if Projects::getItemsByCreationTime(project["uuid"]).empty? then
                options = ["start", "stop"] + options
            end
            if Runner::isRunning(project["uuid"]) then
                options.delete("start")
            else
                options.delete("stop")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
            return if option.nil?
            if option == "start" then
                Runner::start(project["uuid"])
            end
            if option == "stop" then
                Runner::stop(project["uuid"])
            end
            if option == "dive items" then
                items = Projects::getItemsByCreationTime(project["uuid"])
                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|item| Projects::itemBestDescription(item) })
                next if item.nil?
                Projects::diveItem(project, item)
            end
            if option == "set description" then
                project["description"] = CatalystCommon::editTextUsingTextmate(project["description"])
                Projects::saveProject(project)
            end
            if option == "recast" then
                schedule = Projects::makeNewScheduleInteractiveOrNull()
                next if schedule.nil?
                project["schedule"] = schedule
                Projects::saveProject(project)
            end
            if option == "dive ifcs claims" then
                claims = Projects::getIfcsClaimsOfTypeProjectByUuid(project["uuid"])
                loop {
                    ifcsclaim = LucilleCore::selectEntityFromListOfEntitiesOrNull("claim", claims, lambda{|claim| Projects::ifcsClaimToString(claim) })
                    break if ifcsclaim.nil?
                    Projects::diveIfcsClaim(ifcsclaim)
                }
            end
        }
    end

    # Projects::diveItem(project, item)
    def self.diveItem(project, item)
        loop {
            system("clear")
            puts Projects::itemToString(project, item).green
            puts JSON.pretty_generate(item)
            options = [
                "start",
                "open",
                "done",
                "set description",
                "dive ifcs claims"
            ]
            if Runner::isRunning(item["uuid"]) then
                options.delete("start")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?
            if option == "start" then
                Runner::start(item["uuid"])
            end
            if option == "open" then
                CatalystStandardTarget::openTarget(item["target"])
            end
            if option == "done" then
                Projects::detachItemFromProject(project["uuid"], item["uuid"])
            end
            if option == "set description" then
                item["description"] = CatalystCommon::editTextUsingTextmate(item["description"])
                Projects::attachItemToProject(project["uuid"], item)
            end
            if option == "dive ifcs claims" then
                claims = Projects::getIfcsClaimsOfTypeItemtByUuids(project["uuid"], item["uuid"])
                loop {
                    ifcsclaim = LucilleCore::selectEntityFromListOfEntitiesOrNull("claim", claims, lambda{|claim| Projects::ifcsClaimToString(claim) })
                    break if ifcsclaim.nil?
                    Projects::diveIfcsClaim(ifcsclaim)
                }
            end
        }
    end

    def self.diveIfcsClaim(claim)
        loop {
            system("clear")
            puts Projects::ifcsClaimToString(claim).green
            puts JSON.pretty_generate(claim)
            options = [
                "start"
            ]
            if Runner::isRunning(claim["uuid"]) then
                options.delete("start")
            end
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
            break if option.nil?

            if option == "start" then
                Runner::start(claim["uuid"])
            end
        }
    end
end



