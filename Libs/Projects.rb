# encoding: UTF-8

class Projects

    # Projects::toString(project)
    def self.toString(project)
        "[project] #{project["description"]}"
    end

    # Projects::toStringListing(project)
    def self.toStringListing(project)
        ratio = BankExtended::completionRatioRelativelyToTimeCommitmentInHoursPerWeek(project["uuid"], project["timeCommitmentInHoursPerWeek"])
        "[project] (completion: #{"%6.2f" % (ratio*100)} % of #{"%4.1f" % project["timeCommitmentInHoursPerWeek"]}) #{project["description"]}"
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
        CoreDataTx::delete(project["uuid"])
    end

    # Projects::access(project)
    def self.access(project)

        uuid = project["uuid"]

        nxball = BankExtended::makeNxBall([uuid])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Project running for more than an hour")
                end
            }
        }

        system("clear")

        puts "starting: #{Projects::toString(project)} ( uuid: #{project["uuid"]} )".green

        coordinates = Nx102::access(project["contentType"], project["payload"])
        if coordinates then
            project["contentType"] = coordinates[0]
            project["payload"]     = coordinates[1]
            CoreDataTx::commit(project)
        end

        loop {

            system("clear")

            puts "running: #{Projects::toString(project)} ( uuid: #{project["uuid"]} ) for #{((Time.new.to_f - nxball["startUnixtime"]).to_f/3600).round(2)} hours".green

            recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
            ratio = (recoveryTime*7).to_f/project["timeCommitmentInHoursPerWeek"]
            puts "ratio: #{ratio}"
            
            puts "timeCommitmentInHoursPerWeek: #{project["timeCommitmentInHoursPerWeek"]}"

            puts "access | <datecode> | update description / time commitment | new item | detach running | completed | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                coordinates = Nx102::access(project["contentType"], project["payload"])
                if coordinates then
                    project["contentType"] = coordinates[0]
                    project["payload"]     = coordinates[1]
                    CoreDataTx::commit(project)
                end
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(project["description"])
                next if description == ""
                project["description"] = description
                CoreDataTx::commit(project)
                next
            end

            if Interpreting::match("update time commitment", command) then
                timeCommitmentInHoursPerWeek = LucilleCore::askQuestionAnswerAsString("timeCommitmentInHoursPerWeek (empty for abort): ")
                next if timeCommitmentInHoursPerWeek == ""
                timeCommitmentInHoursPerWeek = [timeCommitmentInHoursPerWeek.to_f, 0.5].max # at least 30 mins
                project["timeCommitmentInHoursPerWeek"] = timeCommitmentInHoursPerWeek
                CoreDataTx::commit(project)
                next
            end

            if Interpreting::match("detach running", command) then
                DetachedRunning::issueNew2(Projects::toString(project), Time.new.to_i, [uuid])
                break
            end

            if Interpreting::match("completed", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy project ? ") then
                    CoreDataTx::delete(project["uuid"])
                    break
                end
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)
    end

    # Projects::projectToNS16(project)
    def self.projectToNS16(project)
        uuid = project["uuid"]
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        ratio = BankExtended::completionRatioRelativelyToTimeCommitmentInHoursPerWeek(project["uuid"], project["timeCommitmentInHoursPerWeek"])
        metric = (ratio < 1 ? ["ns:time-commitment", ratio] : ["ns:low-priority-time-commitment", ratio])
        announce = Projects::toStringListing(project).gsub("[project]", "[proj]")
        if ratio >= 1 then
            announce = announce.red
        end
        {
            "uuid"         => uuid,
            "metric"       => metric,
            "announce"     => announce,
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

    # Projects::main()
    def self.main()

        loop {
            system("clear")

            projects = CoreDataTx::getObjectsBySchema("project")
                .sort{|p1, p2| BankExtended::stdRecoveredDailyTimeInHours(p1["uuid"]) <=> BankExtended::stdRecoveredDailyTimeInHours(p2["uuid"]) }

            projects.each_with_index{|project, indx| 
                puts "[#{indx}] #{Projects::toStringListing(project)}"
            }

            puts "<item index> | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                project = projects[indx]
                next if project.nil?
                Projects::access(project)
            end
        }
    end
end
