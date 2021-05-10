
# encoding: UTF-8

# -----------------------------------------------------------------------


=begin

items are marbles in the folder: "/Users/pascal/Galaxy/Documents/NyxSpace/534916595068-01/06a4a51e/The Guardian/Pascal Work/03 Work Marbles"

marble keys:
    uuid        : String
    unixtime    : Integer
    description : String
    text        : String 
    WorkItemType: null (forbackward compatibility) # equivalent of "General" | "General" | "PR" | "RotaItem"


PreNS16 {
    "uuid"        : String
    "description" : String
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

    # WorkInterface::filepathsInUnixtimeOrder()
    def self.filepathsInUnixtimeOrder()
        filter = lambda{|location|
            return false if !File.file?(location)
            File.basename(location)[-7, 7] == ".marble"
        }
        LucilleCore::enumeratorLocationsInFileHierarchyWithFilter($WorkInterface_WorkFolderPath, filter)
            .sort{|f1, f2| Marbles::get(f1, "unixtime") <=> Marbles::get(f2, "unixtime") }
    end

    # WorkInterface::sanitiseDescriptionForBasename(description)
    def self.sanitiseDescriptionForBasename(description)
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

    # WorkInterface::issueNewItem()
    def self.issueNewItem()

        decideFolderPath = lambda{|wit, description|
            if ["General", "RotaItem"].include?(wit) then
                return "#{$WorkInterface_WorkFolderPath}/#{Time.new.strftime("%Y-%m-%d")} #{WorkInterface::sanitiseDescriptionForBasename(description)}"
            end
            if wit == "PR" then
                return "#{$WorkInterface_WorkFolderPath}/#{Time.new.strftime("%Y-%m-%d")} PR {#{SecureRandom.hex(2)}}"
            end
            raise "af8ed9c8-6132-4ac9-b412-71de104b6eac"
        }

        descriptionPrompt = lambda{|wit|
            if ["General", "RotaItem"].include?(wit) then
                return "description (empty to abort): "
            end
            if wit == "PR" then
                return "pr link (empty to abort): "
            end
            raise "af8ed9c8-6132-4ac9-b412-71de104b6eac"
        }

        workItemType = (WorkInterface::interactivelyDecideAWorkItemTypeOrNull() || "General")
        description = LucilleCore::askQuestionAnswerAsString(descriptionPrompt.call(workItemType))
        return if (description == "")
        uuid = SecureRandom.hex(6)
        folderpath = decideFolderPath.call(workItemType, description)
        FileUtils.mkdir(folderpath)
        filepath = "#{folderpath}/00-#{SecureRandom.hex}.marble"
        Marbles::issueNewEmptyMarbleFile(filepath)
        Marbles::set(filepath, "uuid", uuid)
        Marbles::set(filepath, "unixtime", Time.new.to_i)
        Marbles::set(filepath, "description", description)
        Marbles::set(filepath, "WorkItemType", workItemType)
        if ["General", "RotaItem"].include?(workItemType) then
            filepath2 = "#{folderpath}/01-README.txt"
            FileUtils.touch(filepath2)
            system("open '#{filepath2}'")
        end
        puts "work marble (#{workItemType}) created"
    end

    # WorkInterface::filepathToDescription(filepath)
    def self.filepathToDescription(filepath)
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

        if LucilleCore::askQuestionAnswerAsBoolean("move to archives ? ") then
            LucilleCore::removeFileSystemLocation(filepath) # Removing the marble file itself which doesn't need to be in the archives
            folderpath = File.dirname(filepath)
            puts "Moving folder: '#{folderpath}' to archives"
            WorkInterface::moveFolderToArchiveWithDatePrefix(folderpath)
        else
            puts "Removing folder: '#{folderpath}'"
            LucilleCore::removeFileSystemLocation(folderpath)
        end
    end

    # WorkInterface::ns16s()
    def self.ns16s()
        return [] if !Utils::isWorkTime()

        WorkInterface::filepathsInUnixtimeOrder()
            .to_a
            .map{|filepath| 
                uuid = Marbles::get(filepath, "uuid")
                description = WorkInterface::filepathToDescription(filepath)
                {
                    "uuid"     => uuid,
                    "announce" => "(#{"%5.3f" % BankExtended::stdRecoveredDailyTimeInHours(uuid)}) #{"[work]".green} #{description}",
                    "start"    => lambda {

                        startUnixtime = Time.new.to_f

                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Utils::onScreenNotification("Catalyst", "Todo (work) running for more than an hour")
                                sleep 60
                            }
                        }

                        loop {

                            description = WorkInterface::filepathToDescription(filepath)

                            puts "[work] #{description}".green

                            text = Marbles::get(filepath, "text").strip
                            if text.size > 0 then
                                puts "----------------------------------------"
                                puts text.green
                                puts "----------------------------------------"
                            end 

                            system("open '#{File.dirname(filepath)}'")

                            puts "access | edit description | ++ (postpone today by one hour) | done".yellow

                            command = LucilleCore::askQuestionAnswerAsString("> ")

                            break if command == ""

                            if Interpreting::match("access", command) then
                                system("open '#{File.dirname(filepath)}'")
                                next
                            end

                            if Interpreting::match("edit description", command) then
                                description = Utils::editTextSynchronously(Marbles::get(filepath, "description"))
                                Marbles::set(filepath, "description", description)
                                next
                            end

                            if Interpreting::match("++", command) then
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                                break
                            end

                            if Interpreting::match("done", command) then
                                WorkInterface::done(filepath)
                                break
                            end
                        }

                        thr.exit

                        timespan = Time.new.to_f - startUnixtime

                        puts "Time since start: #{Time.new.to_f - startUnixtime}"

                        timespan = [timespan, 3600*2].min

                        puts "putting #{timespan} seconds to todo: #{uuid}"
                        Bank::put(uuid, timespan)
                    },
                    "done" => lambda {
                        WorkInterface::done(filepath)
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"])}
    end
end
