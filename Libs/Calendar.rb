# encoding: UTF-8

class Calendar

    # Calendar::pathToCalendarFolder()
    def self.pathToCalendarFolder()
        "/Users/pascal/Galaxy/Calendar"
    end

    # Calendar::issue(date, description)
    def self.issue(date, description)
        foldername = "#{date} | #{description}"
        folderpath = "#{Calendar::pathToCalendarFolder()}/02-Future/#{foldername}"
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
        LucilleCore::locationsAtFolder("#{Calendar::pathToCalendarFolder()}/02-Future").map{|folderpath|
            pair = File.basename(folderpath).split("|").map{|s| s.strip }
            {
                "date" => pair[0],
                "description" => pair[1],
                "folderpath" => folderpath
            }
        }
    end

    # Calendar::toString(item)
    def self.toString(item)
        "[calendar] (#{item["date"]}) #{item["description"]}"
    end

    # Calendar::moveToArchives(item)
    def self.moveToArchives(item)
        FileUtils.mv(item["folderpath"], "#{Calendar::pathToCalendarFolder()}/01-Archives")
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
                uuid = Digest::SHA1.hexdigest("4dc9a277-8880-472e-a459-cf1d9b7b6604:#{item["date"]}:#{item["description"]}")
                {
                    "uuid"     => uuid,
                    "announce" => Calendar::toString(item),
                    "access"   => lambda { 
                        if LucilleCore::askQuestionAnswerAsBoolean("'#{Calendar::toString(item)}' done ? ") then
                            Calendar::moveToArchives(item)
                        end
                    },
                    "done"     => lambda {
                        if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to done '#{Calendar::toString(item)}' ? ") then
                            Calendar::moveToArchives(item)
                        end
                    }
                }
            }
    end
end


