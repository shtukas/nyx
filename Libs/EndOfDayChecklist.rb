class EndOfDayChecklist

    # EndOfDayChecklist::lines()
    def self.lines()
        IO.read("#{ENV['HOME']}/Galaxy/DataHub/End-Of-Day-Checklist-[Data].txt")
            .lines
            .map{|line| line.strip }
            .select{|line| line.size > 0 } 
    end

    # EndOfDayChecklist::listingItems()
    def self.listingItems()
        EndOfDayChecklist::lines()
            .map{|line|
                {
                    "uuid"     => Digest::SHA1.hexdigest("db7b7cf6-122f-4b7e-9e14-25094208497e:#{line}"),
                    "mikuType" => "EndOfDayChecklist",
                    "line"     => line
                }
            }
    end
end
