# encoding: UTF-8

=begin
{
    "uuid"        : String
    "projectId"   : String
    "unixtime"    : Float
    "description" : String
    "contentType" : String
    "payload"     : String
}
=end

class ProjectItems

    # ProjectItems::projectItemsDataRepositoryFolderpath()
    def self.projectItemsDataRepositoryFolderpath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Project-Items"
    end

    # ProjectItems::commit(item)
    def self.commit(item)
        BTreeSets::set(ProjectItems::projectItemsDataRepositoryFolderpath(), "9bd4d29e-e2bf-430c-a5ba-b9a145a13d8a", item["uuid"], item)
    end

    # ProjectItems::interativelyIssueNewProjectItem(projectId)
    def self.interativelyIssueNewProjectItem(projectId)
        coordinates = Nx102::interactivelyIssueNewCoordinates3OrNull()
        return if coordinates.nil?
        description, contentType, payload = coordinates
        item = {
            "uuid"          => SecureRandom.uuid,
            "projectId"     => projectId,
            "unixtime"      => Time.new.to_f,
            "description"   => description,
            "contentType"   => contentType,
            "payload"       => payload
        }
        ProjectItems::commit(item)
        item
    end

    # ProjectItems::items()
    def self.items()
        BTreeSets::values(ProjectItems::projectItemsDataRepositoryFolderpath(), "9bd4d29e-e2bf-430c-a5ba-b9a145a13d8a")
    end

    # ProjectItems::itemsForProject(projectId)
    def self.itemsForProject(projectId)
        ProjectItems::items().select{|item| item["projectId"] == projectId }
    end

    # ProjectItems::destroy(item)
    def self.destroy(item)
        BTreeSets::destroy(ProjectItems::projectItemsDataRepositoryFolderpath(), "9bd4d29e-e2bf-430c-a5ba-b9a145a13d8a", item["uuid"])
    end

    # ProjectItems::toString(item)
    def self.toString(item)
        "#{item["description"]} (#{item["contentType"]})"
    end

    # ProjectItems::landing(item)
    def self.landing(item)
        coordinates = Nx102::access(item["contentType"], item["payload"])
        if coordinates then
            item["contentType"] = coordinates[0]
            item["payload"]     = coordinates[1]
            ProjectItems::commit(item)
        end

        loop {
            puts ProjectItems::toString(item).green
            puts "access | delete".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""
            if Interpreting::match("access", command) then
                coordinates = Nx102::access(item["contentType"], item["payload"])
                if coordinates then
                    item["contentType"] = coordinates[0]
                    item["payload"]     = coordinates[1]
                    ProjectItems::commit(item)
                end
                next
            end
            if Interpreting::match("delete", command) then
                ProjectItems::destroy(item)
                break
            end
        }
    end
end 

class Projects

    # Projects::toString(project)
    def self.toString(project)
        "[project] #{project["description"]}"
    end

    # Projects::interactivelyCreateNewProject()
    def self.interactivelyCreateNewProject()

        uuid = SecureRandom.uuid

        description = LucilleCore::askQuestionAnswerAsString("description (empty for abort): ")
        if description == "" then
            return nil
        end

        timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("timeCommitmentInHoursPerWeek (empty for abort): ")
        if timeCommitmentInHoursPerWeek == "" then
            return nil
        end

        timeCommitmentInHoursPerWeek = [timeCommitmentInHoursPerWeek.to_f, 0.5].max # at least 30 mins

        project = {}
        project["uuid"]        = uuid
        project["schema"]      = "project"
        project["unixtime"]    = Time.new.to_i
        project["description"] = description
        project["timeCommitmentInHoursPerWeek"] = timeCommitmentInHoursPerWeek

        CoreDataTx::commit(project)
    end

    # Projects::completeProject(project)
    def self.completeProject(project)
        ProjectItems::itemsForProject(project["uuid"]).each{|item|
            puts "Destroying #{ProjectItems::toString(item)}"
            ProjectItems::destroy(item)
        }
        CoreDataTx::delete(project["uuid"])
        $counterx.registerDone()
    end

    # Projects::access(project)
    def self.access(project)

        uuid = project["uuid"]

        startUnixtime = Time.new.to_f

        thr = Thread.new {
            sleep 3600
            loop {
                Utils::onScreenNotification("Catalyst", "Project running for more than an hour")
                sleep 60
            }
        }

        loop {

            projectItems = ProjectItems::itemsForProject(project["uuid"])

            puts "#{Projects::toString(project)} ( uuid: #{project["uuid"]} )".green
            projectItems.each_with_index{|item, indx|
                puts "[#{indx}] #{ProjectItems::toString(item)}"
            }

            puts "access | <datecode> | update description | new item | completed".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                item = projectItems[indx]
                next if item.nil?
                ProjectItems::landing(item)
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(project["description"])
                next if description == ""
                project["description"] = description
                CoreDataTx::commit(project)
                next
            end

            if Interpreting::match("new item", command) then
                ProjectItems::interativelyIssueNewProjectItem(project["uuid"])
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Projects::toString(project), Time.new.to_i, "bank accounts", [uuid])
                break
            end

            if Interpreting::match("completed", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy project ? ") then
                    Projects::completeProject(project)
                    break
                end
            end
        }

        thr.exit

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to project #{Projects::toString(project)} (uuid: #{uuid})"
        Bank::put(uuid, timespan)

        $counterx.registerTimeInSeconds(timespan)
    end

    # Projects::projectToNS16(project)
    def self.projectToNS16(project)
        uuid = project["uuid"]
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)

        level = 
            if Bank::valueOverTimespan(uuid, 86400*7) < project["timeCommitmentInHoursPerWeek"]*3600 then
                "ns:important"
            else
                "ns:zero"
            end

        {
            "uuid"         => uuid,
            "metric"       => [level, recoveryTime, nil],
            "announce"     => Projects::toString(project),
            "access"       => lambda { Projects::access(project) },
            "done"         => lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("destroy project ? ") then
                    Projects::completeProject(project)
                end
            }
        }
    end

    # Projects::ns16s()
    def self.ns16s()
         CoreDataTx::getObjectsBySchema("project")
            .map{|project| Projects::projectToNS16(project) }
    end
end
