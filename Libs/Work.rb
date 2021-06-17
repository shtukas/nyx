
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
}

=end

$Work_WorkFolderPath = Utils::locationByUniqueStringOrNull("328ed6bd-29c8")
$Work_ArchivesFolderPath = Utils::locationByUniqueStringOrNull("6badde29-8a3d")

if $Work_ArchivesFolderPath.nil? then
    puts "[error: d48c4aa9-8af2] Could not locate the Work folder"
    exit
end

# ----------------------------------------------------------------------------

class Work

    # -- Utils ------------------------------------------------

    # Work::workIsActive()
    def self.workIsActive()
        activityFlag = KeyValueStore::getOrNull(nil, "0daf738e-b46d-4e3c-932c-4eef58bb0467:#{Utils::today()}")
        return true if (activityFlag and activityFlag == "on")
        return false if (activityFlag and activityFlag == "off")
        rt = BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408")
        ratio = rt.to_f/Work::targetRT()
        ratio < 1
    end

    # Work::writeNxC144FB7A(folderpath, uuid)
    def self.writeNxC144FB7A(folderpath, uuid)
        filepath = "#{folderpath}/.NxC144FB7A"
        File.open(filepath, "w") {|f| f.write(uuid) }
    end

    # Work::findItemFolderpathByUUIDOrNull(uuid)
    def self.findItemFolderpathByUUIDOrNull(uuid)
        Find.find(Utils::locationByUniqueStringOrNull("328ed6bd-29c8")) do |path|
            next if !File.file?(path)
            next if File.basename(path) != ".NxC144FB7A"
            next if IO.read(path).strip != uuid
            return File.dirname(path)
        end
        nil
    end

    # Work::sanitiseDescriptionForFilename(description)
    def self.sanitiseDescriptionForFilename(description)
        description = description.gsub(":", " ")
        description = description.gsub("'", " ")
        description = description.gsub("/", " ")
        description.strip
    end

    # Work::selectAWorkItemTypeOrNull()
    def self.selectAWorkItemTypeOrNull()
        types = ["General", "PR", "RotaItem"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("work item type", types)
    end

    # Work::makeDescriptionOrNull(workItemType)
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

    # --------------------------------------------------

    # Work::interactvelyIssueNewItem()
    def self.interactvelyIssueNewItem()
        uuid = SecureRandom.uuid

        workItemType = Work::selectAWorkItemTypeOrNull()
        return if workItemType.nil?

        description = Work::makeDescriptionOrNull(workItemType)
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

        CoreDataTx::commit(workitem)

        if workItemType == "General" then
            folderpath = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{Time.new.to_s[0, 10]} #{Work::sanitiseDescriptionForFilename(description)}"
            FileUtils.mkdir(folderpath)
            Work::writeNxC144FB7A(folderpath, uuid)
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
            folderpath = "#{Utils::locationByUniqueStringOrNull("328ed6bd-29c8")}/#{Time.new.to_s[0, 10]}#{Work::sanitiseDescriptionForFilename(description)}"
            FileUtils.mkdir(folderpath)
            Work::writeNxC144FB7A(folderpath, uuid)
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

    # Work::toString(workitem)
    def self.toString(workitem)
        map1 = {
            "General"  => "",
            "RotaItem" => " [rota]",
            "PR"       => " [pr]"
        }
        "[#{"work".green}]#{map1[workitem["workItemType"]]} #{workitem["description"]}"
    end

    # Work::moveFolderToArchiveWithDatePrefix(folderpath)
    def self.moveFolderToArchiveWithDatePrefix(folderpath)
        date = Time.new.strftime("%Y-%m-%d")
        if !File.basename(folderpath).start_with?(date) then
            folderpath2 = "#{File.dirname(folderpath)}/#{Time.new.strftime("%Y-%m-%d")} #{File.basename(folderpath)}"
            FileUtils.mv(folderpath, folderpath2)
        else
            folderpath2 = folderpath
        end
        FileUtils.mv(folderpath2, $Work_ArchivesFolderPath)
    end

    # Work::done(workitem)
    def self.done(workitem)
        folderpath = Work::findItemFolderpathByUUIDOrNull(workitem["uuid"])
        if folderpath then
            if LucilleCore::askQuestionAnswerAsBoolean("move folder to archives ? ") then
                puts "Moving folder: '#{folderpath}' to archives"
                Work::moveFolderToArchiveWithDatePrefix(folderpath)
            else
                puts "Removing folder: '#{folderpath}'"
                LucilleCore::removeFileSystemLocation(folderpath)
            end
        end
        CoreDataTx::delete(workitem["uuid"])
    end

    # Work::accessItemPR(workitem)
    def self.accessItemPR(workitem)
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
                Work::done(workitem)
                break
            end
        }
    end

    # Work::accessItem(workitem)
    def self.accessItem(workitem)
        
        if workitem["workItemType"] == "PR" then
            Work::accessItemPR(workitem)
            return
        end

        uuid = workitem["uuid"]

        nxball = BankExtended::makeNxBall([uuid, "WORK-E4A9-4BCD-9824-1EEC4D648408"])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = BankExtended::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Work item running for more than an hour")
                end
            }
        }

        loop {

            system("clear")

            puts Work::toString(workitem).green

            puts "trello link        : #{workitem["trelloLink"]}"
            puts "pr link            : #{workitem["prLink"]}"
            puts "git branch         : #{workitem["gitBranch"]}"

            puts "access | edit description | set trello link | pr link | <datecode> | exit | completed".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access", command) then
                folderpath = Work::findItemFolderpathByUUIDOrNull(workitem["uuid"])
                if folderpath.nil? then
                    puts "I could not determine the folder for '#{Work::toString(workitem)}' (uuid: #{workitem["uuid"]})"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                system("open '#{folderpath}'")
                next
            end

            if Interpreting::match("edit description", command) then
                description = Utils::editTextSynchronously(workitem["description"])
                workitem["description"] = description
                CoreDataTx::commit(workitem)

                folderpath1 = "#{Work::findItemFolderpathByUUIDOrNull(uuid)}"
                if folderpath1.nil? then
                    puts "I could not determine the folder for '#{Work::toString(workitem)}' [no folder renaming] (uuid: #{workitem["uuid"]})"
                    LucilleCore::pressEnterToContinue()
                    next
                end

                filename1 = File.basename(folderpath1)
                filename2 = "#{filename1[0, filename1.index(" ")]} #{Work::sanitiseDescriptionForFilename(description)}"
                folderpath2 = "#{File.dirname(folderpath1)}/#{filename2}"

                if folderpath1 != folderpath2 then
                    FileUtils.mv(folderpath1, folderpath2)
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

            if Interpreting::match("completed", command) then
                Work::done(workitem)
                break
            end
        }

        thr.exit

        BankExtended::closeNxBall(nxball, true)

    end

    # Work::targetRT()
    def self.targetRT()
        5
    end

    # Work::ns16s()
    def self.ns16s()
        return [] if !Work::workIsActive()
        rt = BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408")
        ratio = rt.to_f/Work::targetRT()
        work = {
            "uuid"     => "WORK-E4A9-4BCD-9824-1EEC4D648408",
            "announce" => "[#{"work".green}] (rt: #{"%4.2f" % rt} of #{"%3.1f" % Work::targetRT()}) 👩🏻‍💻",
            "access"   => lambda { 
                DetachedRunning::issueNew2("Work", Time.new.to_i, ["WORK-E4A9-4BCD-9824-1EEC4D648408"])
            },
            "done"     => lambda { }
        }
        items = CoreDataTx::getObjectsBySchema("workitem")
            .map{|workitem|
                {
                    "uuid"     => workitem["uuid"],
                    "announce" => Work::toString(workitem),
                    "access"   => lambda { Work::accessItem(workitem) },
                    "done"     => lambda { Work::done(workitem) }
                }
            }
        [work] + items.reverse # The items are coming in the default CoreDataX default unixtime order
    end

    # Work::ns17s()
    def self.ns17s()
        rt = BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408")
        ratio = rt.to_f/Work::targetRT()
        [
            {
                "ratio" => ratio,
                "ns16s" => Work::ns16s()
            }
        ]
    end

    # Work::ns17text()
    def self.ns17text()
        rt = BankExtended::stdRecoveredDailyTimeInHours("WORK-E4A9-4BCD-9824-1EEC4D648408")
        ratio = rt.to_f/Work::targetRT()
        "(ratio: #{"%4.2f" % ratio} of #{"%3.1f" % Work::targetRT()}) Work"
    end

    # Work::main()
    def self.main()
        loop {
            system("clear")

            puts "[work] (focus)"

            workitems = CoreDataTx::getObjectsBySchema("workitem")

            workitems.each_with_index{|workitem, indx|
                puts "[#{indx.to_s.ljust(2)}] #{Work::toString(workitem)}"
            }

            puts "<item index> | new item | exit".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == "exit"

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                workitem = workitems[indx]
                next if workitem.nil?
                Work::accessItem(workitem)
            end

            if Interpreting::match("new item", command) then
                Work::interactvelyIssueNewItem()
            end
        }
    end
end
