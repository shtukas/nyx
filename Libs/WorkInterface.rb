
# encoding: UTF-8

# -----------------------------------------------------------------------


=begin

items are marbles in the folder: "/Users/pascal/Galaxy/Documents/NyxSpace/534916595068-01/06a4a51e/The Guardian/Pascal Work/03 Work Marbles"

marble keys:
    uuid         : String
    unixtime     : Integer
    ordinal      : Float
    description  : String
    WorkItemType : null (forbackward compatibility) # equivalent of "General" | "General" | "PR" | "RotaItem"
    trelloLink   : null or String # URL to Trello board.

# The description is the PR link in the case of WorkItemType == "PR"

=end

$WorkInterface_WorkFolderPath = Utils::locationByUniqueStringOrNull("328ed6bd-29c8")
$WorkInterface_ArchivesFolderPath = Utils::locationByUniqueStringOrNull("6badde29-8a3d")

if $WorkInterface_ArchivesFolderPath.nil? then
    puts "[error: d48c4aa9-8af2] Could not locate the Work folder"
    exit
end

# ----------------------------------------------------------------------------

class WorkInterface

    # WorkInterface::filepaths()
    def self.filepaths()
        filter = lambda{|location|
            return false if !File.file?(location)
            File.basename(location)[-7, 7] == ".marble"
        }
        LucilleCore::enumeratorLocationsInFileHierarchyWithFilter($WorkInterface_WorkFolderPath, filter).to_a
    end

    # WorkInterface::ordinals()
    def self.ordinals()
        WorkInterface::filepaths().map{|filepath|
            Marbles::get(filepath, "ordinal").to_f
        }
    end

    # WorkInterface::sanitiseDescriptionForFilename(description)
    def self.sanitiseDescriptionForFilename(description)
        description = description.gsub(":", " ")
        description = description.gsub("'", " ")
        description = description.gsub("/", " ")
        description.strip
    end

    # WorkInterface::interactivelyDecideAWorkItemTypeOrNull()
    def self.interactivelyDecideAWorkItemTypeOrNull()
        types = ["General", "PR", "RotaItem"]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("work item type", types)
    end

    # WorkInterface::interactivelyDecideADescriptionOrNull(workItemType)
    def self.interactivelyDecideADescriptionOrNull(workItemType)
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

    # WorkInterface::makeNewItemFolderpath(workItemType, description)
    def self.makeNewItemFolderpath(workItemType, description)
        if ["General", "RotaItem"].include?(workItemType) then
            return "#{$WorkInterface_WorkFolderPath}/#{Time.new.strftime("%Y-%m-%d")} #{WorkInterface::sanitiseDescriptionForFilename(description)}"
        end
        if ["PR"].include?(workItemType) then
            return "#{$WorkInterface_WorkFolderPath}/#{Time.new.strftime("%Y-%m-%d")} PR #{SecureRandom.hex(6)}"
        end
        raise "af8ed9c8-6132-4ac9-b412-71de104b6eac"
    end

    # WorkInterface::interactvelyIssueNewItem()
    def self.interactvelyIssueNewItem()
        uuid = SecureRandom.hex(6)

        workItemType = WorkInterface::interactivelyDecideAWorkItemTypeOrNull()
        return if workItemType.nil?

        description = WorkInterface::interactivelyDecideADescriptionOrNull(workItemType)
        return if description.nil?

        folderpath = WorkInterface::makeNewItemFolderpath(workItemType, description)
        FileUtils.mkdir(folderpath)

        ordinal = (WorkInterface::ordinals() + [0]).max + 1

        filepath = "#{folderpath}/00-#{SecureRandom.hex}.marble"

        Marbles::issueNewEmptyMarbleFile(filepath)

        Marbles::set(filepath, "uuid", uuid)
        Marbles::set(filepath, "unixtime", Time.new.to_i)
        Marbles::set(filepath, "ordinal", ordinal)
        Marbles::set(filepath, "description", description)
        Marbles::set(filepath, "WorkItemType", workItemType)

        if ["General", "RotaItem"].include?(workItemType) then
            link = LucilleCore::askQuestionAnswerAsString("trello link (empty for no link): ")
            if link != "" then
                Marbles::set(filepath, "trelloLink", link)
            end
        end

        if ["General", "RotaItem"].include?(workItemType) then
            FileUtils.touch("#{folderpath}/01-README.txt")
            if LucilleCore::askQuestionAnswerAsBoolean("access the folder ? ") then
                system("open '#{folderpath}'")
            end
        end

        puts "work marble (#{workItemType}) created"
    end

    # WorkInterface::toString(filepath)
    def self.toString(filepath)
        "(#{Time.at(Marbles::get(filepath, "unixtime").to_i).to_s[0, 10]}) #{Marbles::get(filepath, "description")}"
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

    # WorkInterface::done(filepath)
    def self.done(filepath)
        $counterx.registerDone()
        itemType = (Marbles::getOrNull(filepath, "WorkItemType") || "General")
        if itemType == "PR" then
            puts "Removing folder: '#{File.dirname(filepath)}'"
            LucilleCore::removeFileSystemLocation(File.dirname(filepath))
            return
        end
        if LucilleCore::locationsAtFolder(File.dirname(filepath)).size == 1 then
            # There only is the marble file.
            LucilleCore::removeFileSystemLocation(File.dirname(filepath))
            return
        end
        if LucilleCore::askQuestionAnswerAsBoolean("move folder to archives ? ") then
            LucilleCore::removeFileSystemLocation(filepath) # Removing the marble file itself which doesn't need to be in the archives
            folderpath = File.dirname(filepath)
            puts "Moving folder: '#{folderpath}' to archives"
            WorkInterface::moveFolderToArchiveWithDatePrefix(folderpath)
        else
            folderpath = File.dirname(filepath)
            puts "Removing folder: '#{folderpath}'"
            LucilleCore::removeFileSystemLocation(folderpath)
        end
    end

    # WorkInterface::accessPR(filepath)
    def self.accessPR(filepath)
        uuid = Marbles::get(filepath, "uuid")
        description = Marbles::get(filepath, "description")
        loop {
            puts "link: '#{description}'".green
            puts "open | done".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("open", command) then
                system("open '#{description}'")
                next
            end

            if Interpreting::match("done", command) then
                WorkInterface::done(filepath)
                break
            end
        }
    end

    # WorkInterface::access(filepath)
    def self.access(filepath)
        uuid = Marbles::get(filepath, "uuid")
        description = Marbles::get(filepath, "description")
        workItemType = Marbles::getOrNull(filepath, "WorkItemType") || "General"

        if workItemType == "PR" then
            WorkInterface::accessPR(filepath)
            return
        end

        startUnixtime = Time.new.to_f

        system("open '#{File.dirname(filepath)}'")

        loop {

            puts WorkInterface::toString(filepath).green
            puts "folder: #{File.dirname(filepath)}"
            puts "ordinal: #{Marbles::get(filepath, "ordinal")}"

            if Marbles::getOrNull(filepath, "trelloLink") then
                puts "trello link: #{Marbles::get(filepath, "trelloLink")}"
            end

            puts "access folder | set top | edit description | set trello link | <datecode> | done".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("access folder", command) then
                system("open '#{File.dirname(filepath)}'")
                next
            end

            if Interpreting::match("set top", command) then
                Marbles::set(filepath, "ordinal", (WorkInterface::ordinals() + [0]).min - 1)
                next
            end

            if Interpreting::match("edit description", command) then
                description = Utils::editTextSynchronously(Marbles::get(filepath, "description"))
                Marbles::set(filepath, "description", description)
                folder1 = File.dirname(filepath)
                folder2 = "#{File.dirname(folder1)}/#{Time.at(Marbles::get(filepath, "unixtime")).to_s[0, 10]} #{WorkInterface::sanitiseDescriptionForFilename(description)}"
                if folder1 != folder2 then
                    FileUtils.mv(folder1, folder2)
                end
                return
            end

            if Interpreting::match("set trello link", command) then
                link = LucilleCore::askQuestionAnswerAsString("trello link: ")
                if link != "" then
                    Marbles::set(filepath, "trelloLink", link)
                end
                next
            end

            if Interpreting::match("done", command) then
                WorkInterface::done(filepath)
                break
            end
        }

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{Time.new.to_f - startUnixtime}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to todo: #{uuid}"
        Bank::put(uuid, timespan)

        $counterx.registerTimeInSeconds(timespan)
    end

    # WorkInterface::ns16s()
    def self.ns16s()
        return [] if !Utils::isWorkTime()
        WorkInterface::filepaths()
            .sort{|f1, f2| Marbles::get(f1, "ordinal").to_f <=> Marbles::get(f2, "ordinal").to_f }
            .reverse
            .map
            .with_index{|filepath, indx|
                makeAnnounce = lambda{|description, workItemType|
                    if workItemType == "PR" then
                        return "#{"[work]".green} [monitor] #{description}"
                    end
                    if workItemType == "RotaItem" then
                        return "#{"[work]".green} [rota] #{description}"
                    end
                    "#{"[work]".green} #{description}"
                }
                uuid = Marbles::get(filepath, "uuid")
                description = Marbles::get(filepath, "description")
                workItemType = Marbles::getOrNull(filepath, "WorkItemType") || "General"
                {
                    "uuid"     => uuid,
                    "metric"   => ["ns:work", nil, indx],
                    "announce" => makeAnnounce.call(description, workItemType),
                    "access"   => lambda { WorkInterface::access(filepath) },
                    "done" => lambda { WorkInterface::done(filepath) }
                }
            }
    end
end
