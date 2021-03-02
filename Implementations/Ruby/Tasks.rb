
# encoding: UTF-8

=begin

Task {
    "uuid" : String
    "text" : String
}

=end

class Tasks

    # Tasks::pathToFile()
    def self.pathToFile()
        "/Users/pascal/Desktop/Tasks.txt"
    end

    # Tasks::loadTasksFromDisk()
    def self.loadTasksFromDisk()
        default = {
            "uuid" => SecureRandom.hex,
            "text" => ""
        }
        IO.read(Tasks::pathToFile())
            .lines
            .reduce([default]) {|tasks, line|
                if line.strip == "@item:new" then
                    line = "@item:#{SecureRandom.hex}"
                end 
                if line.start_with?("@item:") then
                    task = {
                        "uuid" => line.strip[6, 999],
                        "text" => ""
                    }
                    tasks + [task]
                else
                    task = tasks.pop
                    task["text"] = task["text"] + line
                    tasks + [task]
                end
            }
            .map{|task|
                task["text"] = task["text"].strip
                task
            }
            .reject{|task| task["text"].size == 0 }
    end

    # Tasks::writeTasksToDisk(tasks)
    def self.writeTasksToDisk(tasks)
        filecontents = tasks.map{|task|
            "@item:#{task["uuid"]}\n#{task["text"]}"
        }
        .join("\n\n")
        File.open(Tasks::pathToFile(), "w"){|f| f.puts(filecontents) }
    end

    # Tasks::applyNextTransformation()
    def self.applyNextTransformation()
        CatalystUtils::applyNextTransformationToFile(Tasks::pathToFile())
    end

    # Tasks::rewriteFileWithoutThisTask(uuid)
    def self.rewriteFileWithoutThisTask(uuid)
        tasks = Tasks::loadTasksFromDisk()
        tasks = tasks.reject{|task| task["uuid"] == uuid }
        Tasks::writeTasksToDisk(tasks)
    end

    # Tasks::rewriteFileWithThisUpdatedTask(task)
    def self.rewriteFileWithThisUpdatedTask(task)
        tasks = Tasks::loadTasksFromDisk()
        tasks = tasks.reject{|t| t["uuid"] == task["uuid"] }
        tasks = tasks + [task]
        Tasks::writeTasksToDisk(tasks)        
    end

    # Tasks::displayGroup()
    def self.displayGroup()

        displayItemsNS16 = Tasks::loadTasksFromDisk()
            .sort{|t1, t2| BankExtended::recoveredDailyTimeInHours(t1["uuid"]) <=> BankExtended::recoveredDailyTimeInHours(t2["uuid"])}
            .first(5)
            .map
            .with_index{|task, indx|
                x1 = BankExtended::recoveredDailyTimeInHours(task["uuid"])
                x2 = (indx == 0) ? ("Task:\n" + task["text"].lines.first(6).map{|line| "         "+line }.join().strip + "\n") : "Task: #{task["text"].lines.first.strip}"
                announce = "(#{"%6.3f" % x1}) #{x2}"
                {
                    "uuid"        => task["uuid"],
                    "announce"    => announce,
                    "lambda"      => lambda{
                        thr = Thread.new {
                            sleep 3600
                            loop {
                                Miscellaneous::onScreenNotification("Catalyst", "Item running for more than an hour")
                                sleep 60
                            }
                        }
                        time1 = Time.new.to_f
                        loop {
                            system("clear")
                            puts ""
                            puts task["text"].green
                            puts ""
                            puts "[] | edit | exit | destroy | ;;".yellow
                            input = LucilleCore::askQuestionAnswerAsString("> ")
                            break if input == ""
                            if input == "[]" then
                                puts "Not implemented yet"
                                LucilleCore::pressEnterToContinue()
                            end
                            if input == "edit" then
                                task["text"] = CatalystUtils::editTextSynchronously(task["text"])
                                Tasks::rewriteFileWithThisUpdatedTask(task)
                            end
                            if input == "exit" then
                                break
                            end
                            if input == "destroy" then
                                Tasks::rewriteFileWithoutThisTask(task["uuid"])
                                break
                            end
                            if input == ";;" then
                                Tasks::rewriteFileWithoutThisTask(task["uuid"])
                                break
                            end
                        }
                        time2 = Time.new.to_f
                        timespan = time2 - time1
                        timespan = [timespan, 3600*2].min
                        puts "putting #{timespan} seconds to task: #{task["uuid"]}"
                        Bank::put(task["uuid"], timespan)
                        thr.exit
                    }
                }
            }

        {
            "uuid"             => "3e69fecb-0a1e-450c-8b96-a16110de5a58",
            "completionRatio"  => 0.1, # To be after the priority items
            "DisplayItemsNS16" => displayItemsNS16
        }
    end
end

