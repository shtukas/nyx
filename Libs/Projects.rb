# encoding: UTF-8

=begin
{
    "uuid" : String
    
}
=end

class ProjectItems
    # ProjectItems::issueNew2(description, startUnixtime, type, payload)
    def self.issueNew2(description, startUnixtime, type, payload)
        raise "df3dc3a4-3962-42c2-92e8-e08c28a51081" if !["bank accounts", "counterx"].include?(type)
        item = {
            "uuid"          => SecureRandom.uuid,
            "description"   => description,
            "startUnixtime" => startUnixtime,
            "type"          => type,
            "payload"       => payload
        }
        BTreeSets::set(nil, "72ddaf05-e70e-4480-885c-06c00527025b", item["uuid"], item)
    end

    # ProjectItems::items()
    def self.items()
        BTreeSets::values(nil, "72ddaf05-e70e-4480-885c-06c00527025b")
    end

    # ProjectItems::done(item)
    def self.done(item)
        timespan = [Time.new.to_i - item["startUnixtime"], 3600*2].min
        if item["type"] == "bank accounts" then
            item["BankAccounts"].each{|account|
                puts "Putting #{timespan} seconds into account: #{account}"
                Bank::put(account, timespan)
            }
        end
        if item["type"] == "counterx" then
            puts "putting #{timespan} seconds to CounterX"
            $counterx.registerTimeInSeconds(timespan)
        end
        BTreeSets::destroy(nil, "72ddaf05-e70e-4480-885c-06c00527025b", item["uuid"])
    end

    # ProjectItems::ns16s()
    def self.ns16s()
        ProjectItems::items()
        .map
        .with_index{|item, indx|
            {
                "uuid"     => item["uuid"],
                "metric"   => ["ns:running", nil, indx],
                "announce" => "[detached running] #{item["description"]}".green,
                "access"   => lambda{
                    if LucilleCore::askQuestionAnswerAsBoolean("stop ? : ") then
                        ProjectItems::done(item)
                    end
                },
                "done"     => lambda { ProjectItems::done(item) }
            }
        }
    end
end 

class Projects

    # Projects::repositoryFolderPath()
    def self.repositoryFolderPath()
        "#{Utils::catalystDataCenterFolderpath()}/Projects"
    end

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

        directoryFilename = LucilleCore::timeStringL22()

        folderpath = "#{Projects::repositoryFolderPath()}/#{directoryFilename}"
        FileUtils.mkdir(folderpath)

        project = {}
        project["uuid"]              = uuid
        project["schema"]            = "project"
        project["unixtime"]          = Time.new.to_i
        project["description"]       = description
        project["directoryFilename"] = directoryFilename
        project["timeCommitmentInHoursPerWeek"] = timeCommitmentInHoursPerWeek

        CoreDataTx::commit(project)

        if LucilleCore::askQuestionAnswerAsBoolean("access the folder ? ") then
            system("open '#{folderpath}'")
        end
    end

    # Projects::access(project)
    def self.access(project)
        startUnixtime = Time.new.to_f

        uuid = project["uuid"]

        folderpath = "#{Projects::repositoryFolderPath()}/#{project["directoryFilename"]}"

        system("open '#{folderpath}'")

        loop {

            puts Projects::toString(project).green

            puts "access | <datecode> | completed".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                system("open '#{folderpath}'")
                next
            end

            if Interpreting::match("update description", command) then
                description = Utils::editTextSynchronously(project["description"])
                next if description == ""
                project["description"] = description
                CoreDataTx::commit(project)
                next
            end

            if Interpreting::match("completed", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy project object and project folder ? ") then
                    CoreDataTx::delete(project["uuid"])
                    LucilleCore::removeFileSystemLocation(folderpath)
                    break
                end
            end
        }

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
        folderpath = "#{Projects::repositoryFolderPath()}/#{project["directoryFilename"]}"
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
                if LucilleCore::askQuestionAnswerAsBoolean("destroy project object and project folder ? ") then
                    CoreDataTx::delete(project["uuid"])
                    LucilleCore::removeFileSystemLocation(folderpath)
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
