# encoding: UTF-8

class Quarks

    # Quarks::coreData2SetUUID()
    def self.coreData2SetUUID()
        "catalyst:d0af5f97-2b44-4bf5-8179-07bcdbbcd7ab"
    end

    # Quarks::items()
    def self.items()
        CoreData2::getSet(Quarks::coreData2SetUUID())
            .sort{|i1, i2| i1["unixtime"]<=>i2["unixtime"] }
    end

    # Operations

    # Quarks::toString(item)
    def self.toString(item)
        "[quark] #{CoreData2::toString(atom)} (#{atom["type"]})"
    end

    # Quarks::issueItemUsingLocation(location, unixtime)
    def self.issueItemUsingLocation(location, unixtime)
        description = File.basename(location)
        atom = CoreData2::issueAionPointAtomUsingLocation(SecureRandom.uuid, description, location, [Quarks::coreData2SetUUID()])
        atom["unixtime"] = unixtime
        CoreData2::commitAtom2(atom)
        atom
    end

    # Quarks::importspread()
    def self.importspread()
        locations = LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Quarks Spread")

        if locations.size > 0 then

            unixtimes = Quarks::items().map{|item| item["unixtime"] }

            if unixtimes.size < 2 then
                start1 = Time.new.to_f - 86400
                end1   = Time.new.to_f
            else
                start1 = unixtimes.min
                end1   = [unixtimes.max, Time.new.to_f].max
            end

            spread = end1 - start1

            step = spread.to_f/locations.size

            cursor = start1

            #puts "Quarks Spread"
            #puts "  start : #{Time.at(start1).to_s} (#{start1})"
            #puts "  end   : #{Time.at(end1).to_s} (#{end1})"
            #puts "  spread: #{spread}"
            #puts "  step  : #{step}"

            locations.each{|location|
                cursor = cursor + step
                puts "[quark] (#{Time.at(cursor).to_s}) #{location}"
                Quarks::issueItemUsingLocation(location, cursor)
                LucilleCore::removeFileSystemLocation(location)
            }
        end
    end
end

Thread.new {
    loop {
        sleep 3600
        while Nx50s::nx50sForDomain("(eva)").size <= 50 do
            Quarks::items()
                .take(1)
                .each{|atom|
                    puts "Nx50 <- #{Quarks::toString(atom)}"
                    atom["domain"] = "(eva)"
                    CoreData2::commitAtom2(atom)
                    CoreData2::addAtomToSet(atom["uuid"], Nx50s::coreData2SetUUID())
                    CoreData2::removeAtomFromSet(atom["uuid"], Quarks::coreData2SetUUID())
                }
        end
    }
}
