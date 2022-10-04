class EndOfDayChecklist

    # EndOfDayChecklist::lines()
    def self.lines()
        IO.read("#{ENV['HOME']}/Galaxy/DataHub/Catalyst/End-Of-Day-Checklist.txt")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 } 
    end

    # EndOfDayChecklist::isDoneForToday(item)
    def self.isDoneForToday(item)
        XCache::getFlag("598d3c57-3aca-4f87-a123-8c5a6702c4ee:#{CommonUtils::today()}:#{item["uuid"]}")
    end

    # EndOfDayChecklist::doneForToday(item)
    def self.doneForToday(item)
        XCache::setFlag("598d3c57-3aca-4f87-a123-8c5a6702c4ee:#{CommonUtils::today()}:#{item["uuid"]}", true)
    end

    # EndOfDayChecklist::listingItems()
    def self.listingItems()
        if Time.new.hour < 21 then
            return []
        end
        EndOfDayChecklist::lines()
            .map{|line|
                {
                    "uuid"     => Digest::SHA1.hexdigest("db7b7cf6-122f-4b7e-9e14-25094208497e:#{CommonUtils::today()}:#{line}"),
                    "mikuType" => "EndOfDayChecklist",
                    "line"     => line
                }
            }
            .select{|item| !EndOfDayChecklist::isDoneForToday(item) }
    end
end
