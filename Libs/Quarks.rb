# encoding: UTF-8

class Quarks

    # Quarks::databaseFilepath2()
    def self.databaseFilepath2()
        "#{Utils::catalystDataCenterFolderpath()}/Items/Quarks.sqlite3"
    end

    # Quarks::items()
    def self.items()
        db = SQLite3::Database.new(Quarks::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_ order by _unixtime_") do |row|
            answer << {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"]
            }
        end
        db.close
        answer
    end

    # Quarks::commitItemToDatabase(item)
    def self.commitItemToDatabase(item)
        db = SQLite3::Database.new(Quarks::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [item["uuid"]]
        db.execute "insert into _items_ (_uuid_, _unixtime_, _description_, _coreDataId_) values (?,?,?,?)", [item["uuid"], item["unixtime"], item["description"], item["coreDataId"]]
        db.commit 
        db.close
    end

    # Quarks::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        db = SQLite3::Database.new(Quarks::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        item = nil
        db.execute( "select * from _items_ where _uuid_=?" , [uuid] ) do |row|
            item = {
                "uuid"        => row["_uuid_"],
                "unixtime"    => row["_unixtime_"],
                "description" => row["_description_"],
                "coreDataId"  => row["_coreDataId_"]
            }
        end
        db.close
        item
    end

    # Quarks::delete(uuid)
    def self.delete(uuid)
        db = SQLite3::Database.new(Quarks::databaseFilepath2())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _items_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # Operations

    # Quarks::toString(item)
    def self.toString(item)
        "[quark] #{item["description"]} (#{Nx50s::getItemType(item)})"
    end

    # Quarks::issueItemUsingLocation(location, unixtime)
    def self.issueItemUsingLocation(location, unixtime)
        uuid        = LucilleCore::timeStringL22()
        description = File.basename(location)
        coreDataId = CoreData::issueAionPointDataObjectUsingLocation(location)
        Quarks::commitItemToDatabase({
            "uuid"        => uuid,
            "unixtime"    => unixtime,
            "description" => description,
            "coreDataId"  => coreDataId
        })
        Quarks::getItemByUUIDOrNull(uuid)
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
                .each{|item|
                    puts "Nx50 <- #{Quarks::toString(item)}"
                    item["domain"] = "(eva)"
                    Nx50s::commitItemToDatabase(item)
                    Quarks::delete(item["uuid"])
                }
        end
    }
}
