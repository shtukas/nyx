# encoding: UTF-8

class Calendar

    # Calendar::pathToCalendarFolder()
    def self.pathToCalendarFolder()
        "/Users/pascal/Galaxy/Calendar"
    end

    # Calendar::pathToArchivesFolder()
    def self.pathToArchivesFolder()
        folderpath = "/Users/pascal/Galaxy/Documents/30 Timeline/#{Time.new.strftime("%Y")}/Calendar (Catalyst)"
        raise "d1d363cb-1b34-4091-bd87-455c96ab16e2" if File.exists?(folderpath)
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
                    "metric"   => ["ns:admin", nil],
                    "announce" => Calendar::toString(item).gsub("[calendar]", "[cale]"),
                    "access"   => lambda {
                        if hasElementsInFolder then
                            system("open '#{folderpath}'")
                            LucilleCore::pressEnterToContinue()
                        end
                        if LucilleCore::askQuestionAnswerAsBoolean("'#{Calendar::toString(item)}' done ? ") then
                            Calendar::moveToArchives(item)
                        end
                    },
                    "done"     => lambda {
                        if hasElementsInFolder then
                            system("open '#{folderpath}'")
                            LucilleCore::pressEnterToContinue()
                        end
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to done '#{Calendar::toString(item)}' ? ") then
                            Calendar::moveToArchives(item)
                        end
                    }
                }
            }
    end

    # -----------------------------------------------------

    # Calendar::main()
    def self.main()
        puts "Calendar::main() has not been implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end


