# encoding: UTF-8

class Calendar

    # Calendar::issue(date, description)
    def self.issue(date, description)
        foldername = "#{date} | #{description}"
        folderpath = "/Users/pascal/Galaxy/Documents/Calendar/02-Future/#{foldername}"
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
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/Documents/Calendar/02-Future").map{|folderpath|
            pair = File.basename(folderpath).split("|").map{|s| s.strip }
            {
                "date" => pair[0],
                "description" => pair[1]
            }
        }
    end
end


