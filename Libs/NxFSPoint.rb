
# encoding: UTF-8

class NxFSPoint

    # NxFSPoint::extractNxP1IdOrNull(str)
    def self.extractNxP1IdOrNull(str)
        position = str.index("NxP1")
        return nil if position.nil?
        str[position, 13]
    end

    # NxFSPoint::extractNxP1NamingOrNull(filename)
    def self.extractNxP1NamingOrNull(filename)
        id = NxFSPoint::extractNxP1IdOrNull(filename)
        return nil if id.nil?
        description = filename
            .gsub("(#{id})", "")
            .gsub("[#{id}]", "")
            .gsub(id, "")
            .strip
        {
            "id" => id,
            "description" => description
        }
    end

    # NxFSPoint::processLocation(folderpath)
    def self.processLocation(folderpath)
        naming = NxFSPoint::extractNxP1NamingOrNull(File.basename(folderpath))
        return if naming.nil?
        puts "Processing: #{folderpath}"
        pointId          = naming["id"]
        registrationTime = Time.new.to_i
        description      = naming["description"]
        NxFSPoint::register(pointId, registrationTime, description)
    end

    # NxFSPoint::galaxyScanner()
    def self.galaxyScanner()
        Find.find("/Users/pascal/Galaxy") do |location|
            Find.prune if location.include?("node_modules")
            Find.prune if location.include?("theguardian-github-repositories-Lucille18")
            NxFSPoint::processLocation(location)
        end
    end

    # -------------------------------------------------------------

    # NxFSPoint::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/NxFSPoints.sqlite3"
    end

    # NxFSPoint::register(pointId, registrationTime, description)
    def self.register(pointId, registrationTime, description)
        db = SQLite3::Database.new(NxFSPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _items_ where _pointId_=?", [pointId]
        db.execute "insert into _items_ (_pointId_, _registrationTime_, _description_) values (?,?,?)", [pointId, registrationTime, description]
        db.close
    end

    # NxFSPoint::delete(pointId)
    def self.delete(pointId)
        db = SQLite3::Database.new(NxFSPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _items_ where _pointId_=?", [pointId]
        db.close
    end

    # NxFSPoint::points(): Array[NxFSPoint]
    def self.points()
        db = SQLite3::Database.new(NxFSPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_" , [] ) do |row|
            answer << {
                "uuid"        => row["_pointId_"],
                "entityType"  => "NxFSPoint",
                "datetime"    => Time.new.utc.iso8601,
                "description" => row["_description_"]
            }
        end
        db.close
        answer
    end

    # NxFSPoint::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        db = SQLite3::Database.new(NxFSPoint::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _items_ where _pointId_=?" , [uuid] ) do |row|
            answer = {
                "uuid"        => row["_pointId_"],
                "entityType"  => "NxFSPoint",
                "datetime"    => Time.new.utc.iso8601,
                "description" => row["_description_"]
            }
        end
        db.close
        answer
    end

    # ----------------------------------------------------------------------

    # NxFSPoint::toString(object)
    def self.toString(object)
        "[FSPoint] #{object["description"]}"
    end

    # NxFSPoint::selectOneNxFSPointOrNull()
    def self.selectOneNxFSPointOrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxFSPoint::points(), lambda{|obj| obj["description"] })
    end

    # NxFSPoint::landing(point)
    def self.landing(point)
        loop {

            system("clear")

            puts NxFSPoint::toString(point).green

            puts "uuid: #{point["uuid"]}"

            puts ""

            connected = []

            Links::entities(point["uuid"])
                .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                .each_with_index{|entity, indx| 
                    connected << entity
                    puts "[#{indx}] [linked] #{NyxEntities::toString(entity)}"
                }

            puts ""

            puts "access | connect | disconnect | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = connected[indx]
                next if entity.nil?
                NyxEntities::landing(entity)
            end

            if Interpreting::match("access", command) then
                location = Utils::locationByUniqueStringOrNull(point["uuid"])
                if location.nil? then
                    puts "I could not find the location for point #{point}"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("connect", command) then
                NyxEntities::linkToOtherArchitectured(point)
            end

            if Interpreting::match("disconnect", command) then
                NyxEntities::unlinkFromOther(point)
            end
        }
    end

    # NxFSPoint::nx19s()
    def self.nx19s()
        NxFSPoint::points()
            .map{|point|
                volatileuuid = SecureRandom.hex[0, 8]
                {
                    "announce" => "#{volatileuuid} #{NxFSPoint::toString(point).gsub("[FSPoint]", "[fspt]")}",
                    "type"     => "NxFSPoint",
                    "payload"  => point
                }
            }
    end
end
