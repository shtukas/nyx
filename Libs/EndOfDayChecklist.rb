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
                    "uuid" => SecureRandom.hex,
                    "mikuType" => "EndOfDayChecklist",
                    "line" => line
                }
            }
    end
end
