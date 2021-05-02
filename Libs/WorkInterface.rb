
# encoding: UTF-8

# -----------------------------------------------------------------------


=begin

items are marbles in the folder: "/Users/pascal/Galaxy/Documents/NyxSpace/534916595068-01/06a4a51e/The Guardian/Pascal Work/03 Work Marbles"

marble keys:
    uuid        : String
    unixtime    : Integer
    description : String
    text        : String 


PreNS16 {
    "uuid"        : String
    "description" : String
}

=end

$WorkInterface_WorkFolderPath = "/Users/pascal/Galaxy/Nyx/StdFSTrees/534916595068-01/The Guardian/Pascal Work/02 In Progress [Log]"
$WorkInterface_ArchivesFolderPath = "/Users/pascal/Galaxy/Nyx/StdFSTrees/534916595068-01/The Guardian/Pascal Work/01 Archive [Log]"

if !File.exists?($WorkInterface_WorkFolderPath) then
    puts "The Work Elbram Folder is not at its intended position"
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
    end

    # WorkInterface::issueNewWorkItem()
    def self.issueNewWorkItem()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if (description == "")
        uuid = SecureRandom.hex(6)
        folderpath = "#{$WorkInterface_WorkFolderPath}/#{Time.new.strftime("%Y-%m")} #{description}"
        FileUtils.mkdir(folderpath)
        filepath = "#{folderpath}/00-#{SecureRandom.hex}.marble"
        Marbles::issueNewEmptyElbramFile(filepath)
        Marbles::set(filepath, "uuid", uuid)
        Marbles::set(filepath, "unixtime", Time.new.to_i)
        Marbles::set(filepath, "description", description)
        puts "work marble created"
    end

    # WorkInterface::filepathToDescription(filepath)
    def self.filepathToDescription(filepath)
        "(#{Time.at(Marbles::get(filepath, "unixtime").to_i).to_s[0, 10]}) #{Marbles::get(filepath, "description")}"
    end

    # WorkInterface::ns16s()
    def self.ns16s()
        WorkInterface::filepathsInUnixtimeOrder()
            .to_a
            .reverse
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

                            puts "edit | ++ (postpone today by one hour) | done".yellow

                            command = LucilleCore::askQuestionAnswerAsString("> ")

                            break if command == ""

                            if Interpreting::match("edit description", command) then
                                description = Utils::editTextSynchronously(Marbles::get(filepath, "description"))
                                Marbles::set(filepath, "description", description)
                                next
                            end

                            if Interpreting::match("access", command) then
                                system("open '#{File.dirname(filepath)}'")
                                next
                            end

                            if Interpreting::match("++", command) then
                                DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                                break
                            end

                            if Interpreting::match("done", command) then
                                FileUtils.mv(File.dirname(filepath), $WorkInterface_ArchivesFolderPath)
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
                        system("work api #{uuid} done")
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"])}
    end
end
