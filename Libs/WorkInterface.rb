
# encoding: UTF-8

# -----------------------------------------------------------------------


=begin

WorkItem {
    uuid                : String         # _objectId_
    schema              : "workitem"     # _schema_
    unixtime            : Float          # _unixtime_
    description         : String         # _description_

    "workItemType"      : String         # _payload1_ # "General" | "PR" | "RotaItem"
    "trelloLink"        : String or null # _payload2_
    "prLink"            : String or null # _payload3_
    "gitBranch"         : String or null # _payload4_
    "directoryFilename" : String         # _payload5_
}

=end

$WorkInterface_WorkFolderPath = Utils::locationByUniqueStringOrNull("328ed6bd-29c8")
$WorkInterface_ArchivesFolderPath = Utils::locationByUniqueStringOrNull("6badde29-8a3d")

if $WorkInterface_ArchivesFolderPath.nil? then
    puts "[error: d48c4aa9-8af2] Could not locate the Work folder"
    exit
end

# ----------------------------------------------------------------------------

class WorkInterface

    # WorkInterface::sanitiseDescriptionForFilename(description)
    def self.sanitiseDescriptionForFilename(description)
        description = description.gsub(":", " ")
        description = description.gsub("'", " ")
        description = description.gsub("/", " ")
        description.strip
    end

    # WorkInterface::selectAWorkItemTypeOrNull()
    def self.selectAWorkItemTypeOrNull()
        types = ["General", "PR", "RotaItem"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("work item type", types)
    end

    # WorkInterface::makeDescriptionOrNull(workItemType)
    def self.makeDescriptionOrNull(workItemType)
        if ["General", "RotaItem"].include?(workItemType) then
            description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
            return nil if description == ""
            return description
        end
        if ["PR"].include?(workItemType) then
            description = LucilleCore::askQuestionAnswerAsString("PR link (empty to abort): ")
            return nil if description == ""
            return description
        end
        raise "96b2b823-ddae-403b-b7b8-23058e1df203"
    end

    # WorkInterface::directoryFilenameToFolderpath(namex)
    def self.directoryFilenameToFolderpath(namex)
        "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{namex}"
    end

    # WorkInterface::interactvelyIssueNewItem()
    def self.interactvelyIssueNewItem()
        uuid = SecureRandom.uuid

        workItemType = WorkInterface::selectAWorkItemTypeOrNull()
        return if workItemType.nil?

        description = WorkInterface::makeDescriptionOrNull(workItemType)
        return if description.nil?

        workitem = {}
        workitem["uuid"]              = uuid
        workitem["schema"]            = "workitem"
        workitem["unixtime"]          = Time.new.to_i
        workitem["description"]       = description
        workitem["workItemType"]      = workItemType
        workitem["trelloLink"]        = nil
        workitem["prLink"]            = nil
        workitem["gitBranch"]         = nil
        workitem["directoryFilename"] = nil

        CoreDataTx::commit(workitem)

        if workItemType == "General" then
            folderpath = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{WorkInterface::sanitiseDescriptionForFilename(description)}"
            FileUtils.mkdir(folderpath)
            workitem["directoryFilename"] = File.basename(folderpath)
            FileUtils.touch("#{folderpath}/01-README.txt")
            link = LucilleCore::askQuestionAnswerAsString("trello link (empty for no link): ")
            if link != "" then
                workitem["trelloLink"] = link
            end
            if LucilleCore::askQuestionAnswerAsBoolean("access the folder ? ") then
                system("open '#{folderpath}'")
            end
            CoreDataTx::commit(workitem)
        end

        if workItemType == "RotaItem" then
            folderpath = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{WorkInterface::sanitiseDescriptionForFilename(description)}"
            FileUtils.mkdir(folderpath)
            workitem["directoryFilename"] = File.basename(folderpath)
            FileUtils.touch("#{folderpath}/01-README.txt")
            link = LucilleCore::askQuestionAnswerAsString("trello link (empty for no link): ")
            if link != "" then
                workitem["trelloLink"] = link
            end
            if LucilleCore::askQuestionAnswerAsBoolean("access the folder ? ") then
                system("open '#{folderpath}'")
            end
            CoreDataTx::commit(workitem)
        end

        if workItemType == "PR" then
            workitem["prLink"] = description
            gitbranchname = LucilleCore::askQuestionAnswerAsString("git branch name (empty for nothing): ")
            if gitbranchname != "" then
                workitem["gitBranch"] = gitbranchname
            end
            CoreDataTx::commit(workitem)
        end
    end

    # WorkInterface::toString(workitem)
    def self.toString(workitem)
        map1 = {
            "General"  => "",
            "RotaItem" => " [rota]",
            "PR"       => " [pr]"
        }
        "[work]#{map1[workitem["workItemType"]]} #{workitem["description"]}"
    end

    # WorkInterface::moveFolderToArchiveWithDatePrefix(folderpath)
    def self.moveFolderToArchiveWithDatePrefix(folderpath)
        date = Time.new.strftime("%Y-%m-%d")
        if !File.basename(folderpath).start_with?(date) then
            folderpath2 = "#{File.dirname(folderpath)}/#{Time.new.strftime("%Y-%m-%d")} #{File.basename(folderpath)}"
            FileUtils.mv(folderpath, folderpath2)
        else
            folderpath2 = folderpath
        end
        FileUtils.mv(folderpath2, $WorkInterface_ArchivesFolderPath)
    end

    # WorkInterface::done(workitem)
    def self.done(workitem)
        if workitem["directoryFilename"] then
            folderpath = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{workitem["directoryFilename"]}"
            if LucilleCore::askQuestionAnswerAsBoolean("move folder to archives ? ") then
                puts "Moving folder: '#{folderpath}' to archives"
                WorkInterface::moveFolderToArchiveWithDatePrefix(folderpath)
            else
                puts "Removing folder: '#{folderpath}'"
                LucilleCore::removeFileSystemLocation(folderpath)
            end
        end
        CoreDataTx::delete(workitem["uuid"])
    end

    # WorkInterface::accessPR(workitem)
    def self.accessPR(workitem)
        loop {
            puts "description: #{workitem["description"]}".green
            puts "link       : #{workitem["prLink"]}".green
            puts "git branch : #{workitem["gitBranch"]}".green
            puts "open | done".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("open", command) then
                system("open '#{workitem["prLink"]}'")
                next
            end

            if Interpreting::match("done", command) then
                WorkInterface::done(workitem)
                break
            end
        }
    end

    # WorkInterface::access(workitem)
    def self.access(workitem)
        
        if workitem["workItemType"] == "PR" then
            WorkInterface::accessPR(workitem)
            return
        end

        uuid = workitem["uuid"]
        startUnixtime = Time.new.to_f

        loop {

            puts WorkInterface::toString(workitem).green

            puts "trello link        : #{workitem["trelloLink"]}"
            puts "pr link            : #{workitem["prLink"]}"
            puts "git branch         : #{workitem["gitBranch"]}"
            puts "directory filename : #{workitem["directoryFilename"]}"

            puts "access | edit description | set trello link | pr link | <datecode> | done".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                if workitem["directoryFilename"] then
                    folderpath = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{workitem["directoryFilename"]}"
                    system("open '#{folderpath}'")
                end
                next
            end

            if Interpreting::match("edit description", command) then
                directoryFilename1 = workitem["directoryFilename"]
                description = Utils::editTextSynchronously(workitem["description"])
                workitem["description"] = description
                CoreDataTx::commit(workitem)
                directoryFilename2 = WorkInterface::sanitiseDescriptionForFilename(description)

                folder1 = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{directoryFilename1}"
                folder2 = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{directoryFilename2}"

                if folder1 != folder2 then
                    FileUtils.mv(folder1, folder2)
                end
                return
            end

            if Interpreting::match("set trello link", command) then
                link = LucilleCore::askQuestionAnswerAsString("trello link (empty to abort): ")
                if link != "" then
                    workitem["trelloLink"] = link
                    CoreDataTx::commit(workitem)
                end
                next
            end

            if Interpreting::match("done", command) then
                WorkInterface::done(workitem)
                break
            end
        }

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{Time.new.to_f - startUnixtime}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to todo: #{uuid}"
        Bank::put(uuid, timespan)
    end

    # WorkInterface::ns16s()
    def self.ns16s()
        return [] if !Utils::isWorkTime()
        CoreDataTx::getObjectsBySchema("workitem")
            .sort{|w1, w2| w1["unixtime"] <=> w2["unixtime"] }
            .reverse
            .map{|workitem|
                uuid = workitem["uuid"]
                recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
                {
                    "uuid"     => uuid,
                    "metric"   => ["ns:work", recoveryTime],
                    "announce" => WorkInterface::toString(workitem).green,
                    "access"   => lambda { WorkInterface::access(workitem) },
                    "done"     => lambda { WorkInterface::done(workitem) }
                }
            }
    end
end
