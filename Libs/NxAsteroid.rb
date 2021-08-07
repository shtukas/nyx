
# encoding: UTF-8

class NxAsteroid

    # NxAsteroid::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Asteriods/asteroids.sqlite3"
    end

    # NxAsteroid::databaseRowToNxAsteroid(row): NxAsteroid
    def self.databaseRowToNxAsteroid(row)
        {
            "uuid"        => row["_nyxId_"],
            "entityType"  => "Nx45",
            "datetime"    => Time.at(row["_unixtime_"]).utc.iso8601,
            "location"    => row["_location_"]
        }
    end

    # NxAsteroid::getAsteroidByUUIDOrNull(uuid): null or NxAsteroid
    def self.getAsteroidByUUIDOrNull(uuid)
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _asteroids_ where _nyxId_=?" , [uuid] ) do |row|
            answer = NxAsteroid::databaseRowToNxAsteroid(row)
        end
        db.close
        answer
    end

    # NxAsteroid::asteroids(): Array[NxAsteroid]
    def self.asteroids()
        db = SQLite3::Database.new(NxAsteroid::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _asteroids_" , [] ) do |row|
            answer << NxAsteroid::databaseRowToNxAsteroid(row)
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxAsteroid::toString(nx45)
    def self.toString(nx45)
        "[asteroid] #{File.basename(nx45["location"])}"
    end

    # NxAsteroid::landing(nx45)
    def self.landing(nx45)
        loop {
            nx45 = NxAsteroid::getAsteroidByUUIDOrNull(nx45["uuid"]) # Could have been destroyed or metadata updated in the previous loop
            return if nx45.nil?
            system("clear")

            puts NxAsteroid::toString(nx45).green
            puts "location: #{nx45["location"]}"
            puts ""

            entities = Links::entities(nx45["uuid"])

            entities
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| puts "[#{indx}] [linked] #{NyxEntities::toString(entity)}" }

            puts ""

            puts "access | connect | disconnect".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = entities[indx]
                next if entity.nil?
                NyxEntities::landing(entity)
            end

            if Interpreting::match("access", command) then
                if File.exists?(nx45["location"]) then
                    system("open '#{nx45["location"]}'")
                else
                    puts "Could not find location for asteroid: Ax16-#{nx45["uuid"]}"
                    puts "The latest known location (#{nx45["location"]}) does not exist"
                    LucilleCore::pressEnterToContinue()
                end
            end

            if Interpreting::match("connect", command) then
                NyxEntitieslinkToOtherArchitectured(nx45)
            end

            if Interpreting::match("disconnect", command) then
                NyxEntitiesunlinkFromOther(nx45)
            end
        }
    end

    # NxAsteroid::nx19s()
    def self.nx19s()
        NxAsteroid::asteroids().map{|nx45|
            volatileuuid = SecureRandom.hex[0, 8]
            {
                "announce" => "#{volatileuuid} #{NxAsteroid::toString(nx45)}",
                "type"     => "Nx45",
                "payload"  => nx45
            }
        }
    end
end
