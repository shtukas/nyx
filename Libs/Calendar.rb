# encoding: UTF-8

class Calendar

    # Calendar::pathToCalendarFolder()
    def self.pathToCalendarFolder()
        "/Users/pascal/Galaxy/Calendar"
    end

    # Calendar::pathToCurrentFolder()
    def self.pathToCurrentFolder()
        "#{Calendar::pathToCalendarFolder()}/02-Current"
    end

    # Calendar::pathToArchivesFolder()
    def self.pathToArchivesFolder()
        "#{Calendar::pathToCalendarFolder()}/01-Archives"
    end

    # Calendar::issue(date, description)
    def self.issue(date, description)
        foldername = "#{date} #{description}"
        folderpath = "#{Calendar::pathToCurrentFolder()}/#{foldername}"
        if File.exists?(folderpath) then
            puts "I can't create item #{foldername}, somehow already exists."
            LucilleCore::pressEnterToContinue()
            return
        end
        FileUtils.mkdir(folderpath)
    end

    # Calendar::interactivelyIssueNewCalendarItem()
    def self.interactivelyIssueNewCalendarItem()
        date = LucilleCore::askQuestionAnswerAsString("date 2021-01-01 (time 1200) (empty to abort) : ")
        return if date == ""
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort) : ")
        return if description == ""
        Calendar::issue(date, description)
    end

    # Calendar::items()
    def self.items()
        LucilleCore::locationsAtFolder(Calendar::pathToCurrentFolder()).map{|folderpath|
            basename = File.basename(folderpath)
            date = basename[0, 10]
            description =  basename
            {
                "date"        => date,
                "description" => basename,
                "folderpath"  => folderpath,
            }
        }
    end

    # Calendar::toString(item)
    def self.toString(item)
        "[calendar] #{item["description"]}"
    end

    # Calendar::moveToArchives(item)
    def self.moveToArchives(item)
        return if !File.exist?(item["folderpath"])
        FileUtils.mv(item["folderpath"], Calendar::pathToArchivesFolder())
    end

    # -----------------------------------------------------

    # Calendar::itemIsForNS16s(item)
    def self.itemIsForNS16s(item)
        item["date"] <= Time.new.to_s[0, 10]
    end

    # Calendar::run(item)
    def self.run(item)
        puts Calendar::toString(item)
        folderpath = item["folderpath"]
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
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
                    "start-land" => lambda {
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


