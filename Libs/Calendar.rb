# encoding: UTF-8

class Calendar

    # Calendar::pathToCalendarFolder()
    def self.pathToCalendarFolder()
        "/Users/pascal/Galaxy/Calendar"
    end

    # Calendar::pathToArchivesFolder()
    def self.pathToArchivesFolder()
        l1 = "/Users/pascal/Galaxy/Timeline"
        folderpath = "#{l1}/#{Time.new.strftime("%Y")}/Calendar (Catalyst)"
        raise "d1d363cb-1b34-4091-bd87-455c96ab16e2" if !File.exists?(folderpath) # This will happen first thing after midnight every year
        folderpath
    end

    # Calendar::issue(date, description)
    def self.issue(date, description)
        foldername = "#{date} | #{description}"
        folderpath = "#{Calendar::pathToCalendarFolder()}/#{foldername}"
        if File.exists?(folderpath) then
            puts "I can't create item #{foldername}, somehow already exists."
            LucilleCore::pressEnterToContinue()
            return
        end
        FileUtils.mkdir(folderpath)
    end

    # Calendar::interactivelyIssueNewCalendarItem()
    def self.interactivelyIssueNewCalendarItem()
        date = LucilleCore::askQuestionAnswerAsString("date(time, with dot) (empty to abort) : ")
        return if date == ""
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort) : ")
        return if description == ""
        Calendar::issue(date, description)
    end

    # Calendar::items()
    def self.items()
        LucilleCore::locationsAtFolder(Calendar::pathToCalendarFolder()).map{|folderpath|
            pair = File.basename(folderpath).split("|").map{|s| s.strip }
            {
                "date" => pair[0],
                "description" => "(#{pair[1]}) #{pair[2]}",
                "folderpath" => folderpath
            }
        }
    end

    # Calendar::toString(item)
    def self.toString(item)
        folderpath = item["folderpath"]
        hasElementsInFolder = LucilleCore::locationsAtFolder(folderpath).size > 0
        folderStr = hasElementsInFolder ? " [Folder Elements]" : ""
        "[calendar] (#{item["date"]}) #{item["description"]}#{folderStr}"
    end

    # Calendar::moveToArchives(item)
    def self.moveToArchives(item)
        FileUtils.mv(item["folderpath"], Calendar::pathToArchivesFolder())
    end

    # -----------------------------------------------------

    # Calendar::itemIsForNS16s(item)
    def self.itemIsForNS16s(item)
        item["date"] <= Time.new.to_s[0, 10]
    end

    # Calendar::run(item)
    def self.run(item)
        folderpath = item["folderpath"]
        puts Calendar::toString(item)
        if hasElementsInFolder and LucilleCore::askQuestionAnswerAsBoolean("access folder ? ") then
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
        end
        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
            Calendar::moveToArchives(item)
        end
    end

    # Calendar::ns16s()
    def self.ns16s()
        Calendar::items()
            .select{|item| Calendar::itemIsForNS16s(item) }
            .map{|item|
                folderpath = item["folderpath"]
                hasElementsInFolder = LucilleCore::locationsAtFolder(folderpath).size > 0
                uuid = Digest::SHA1.hexdigest("4dc9a277-8880-472e-a459-cf1d9b7b6604:#{item["date"]}:#{item["description"]}")
                {
                    "uuid"     => uuid,
                    "announce" => Calendar::toString(item).gsub("[calendar]", "[cale]"),
                    "commands" => ["..", "done"],
                    "interpreter" => lambda {|command|
                        if command == ".." then
                            Calendar::run(item)
                        end
                        if command == "done" then
                            Calendar::moveToArchives(item)
                        end
                    },
                    "run" => lambda {
                        Calendar::run(item)
                    }
                }
            }
            .select{|item| DoNotShowUntil::isVisible(item["uuid"]) }
    end

    # -----------------------------------------------------

    # Calendar::main()
    def self.main()
        puts "Calendar::main() has not been implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # Calendar::nx19s()
    def self.nx19s()
        Calendar::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "announce" => Calendar::toString(item),
                "lambda"   => lambda { Calendar::run(item) }
            }
        }
    end
end


