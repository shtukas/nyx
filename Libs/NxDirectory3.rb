
# encoding: UTF-8

class NxDirectory3

    # NxDirectory3::extractNxD3IdOrNull(str)
    def self.extractNxD3IdOrNull(str)
        position = str.index("NxD3")
        return nil if position.nil?
        str[position, 13]
    end

    # NxDirectory3::extractNxD3NamingOrNull(filename)
    def self.extractNxD3NamingOrNull(filename)
        id = NxDirectory3::extractNxD3IdOrNull(filename)
        return nil if id.nil?
        description = filename.gsub(id, "").strip
        {
            "id" => id,
            "description" => description
        }
    end

    # NxDirectory3::processLocation(folderpath)
    def self.processLocation(folderpath)
        naming = NxDirectory3::extractNxD3NamingOrNull(File.basename(folderpath))
        return if naming.nil?
        puts "Processing: #{folderpath}"
        directoryId      = naming["id"]
        registrationTime = Time.new.to_i
        description      = naming["description"]
        NxDirectory3::register(directoryId, registrationTime, description)
    end

    # NxDirectory3::galaxyScanner()
    def self.galaxyScanner()
        Find.find("/Users/pascal/Galaxy") do |location|
            next if !File.directory?(location)
            Find.prune if location.include?("node_modules")
            Find.prune if location.include?("theguardian-github-repositories-Lucille18")
            NxDirectory3::processLocation(location)
        end
    end

    # -------------------------------------------------------------

    # NxDirectory3::databaseFilepath()
    def self.databaseFilepath()
        "#{Config::nyxFolderPath()}/NxDirectories3.sqlite3"
    end

    # NxDirectory3::register(directoryId, registrationTime, description)
    def self.register(directoryId, registrationTime, description)
        db = SQLite3::Database.new(NxDirectory3::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _items_ where _directoryId_=?", [directoryId]
        db.execute "insert into _items_ (_directoryId_, _registrationTime_, _description_) values (?,?,?)", [directoryId, registrationTime, description]
        db.close
    end

    # NxDirectory3::delete(directoryId)
    def self.delete(directoryId)
        db = SQLite3::Database.new(NxDirectory3::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "delete from _items_ where _directoryId_=?", [directoryId]
        db.close
    end

    # NxDirectory3::directories(): Array[NxDirectory3]
    def self.directories()
        db = SQLite3::Database.new(NxDirectory3::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _items_" , [] ) do |row|
            answer << {
                "uuid"        => row["_directoryId_"],
                "entityType"  => "NxDirectory3",
                "datetime"    => Time.new.utc.iso8601,
                "description" => row["_description_"]
            }
        end
        db.close
        answer
    end

    # NxDirectory3::getItemByUUIDOrNull(uuid)
    def self.getItemByUUIDOrNull(uuid)
        db = SQLite3::Database.new(NxDirectory3::databaseFilepath())
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _items_ where _directoryId_=?" , [uuid] ) do |row|
            answer = {
                "uuid"        => row["_directoryId_"],
                "entityType"  => "NxDirectory3",
                "datetime"    => Time.new.utc.iso8601,
                "description" => row["_description_"]
            }
        end
        db.close
        answer
    end

    # NxDirectory3::getDx3ElementsLocationsFromDisk(directoryId)
    def self.getDx3ElementsLocationsFromDisk(directoryId)
        location = Utils::locationByUniqueStringOrNull(directoryId)
        if location.nil? then
            puts "the directory #{directoryId} cannot be found in Galaxy, let's get rid of the record in Nyx"
            LucilleCore::pressEnterToContinue()
            NxDirectory3::delete(directoryId)
            Links::deleteReferencesToUUID(directoryId)
            return []
        end
        LucilleCore::locationsAtFolder(location).select{|l| File.basename(l)[0, 1] != "." }
    end

    # ----------------------------------------------------------------------

    # NxDirectory3::toString(object)
    def self.toString(object)
        "[Directory3] #{object["description"]}"
    end

    # NxDirectory3::selectOneNxDirectory3OrNull()
    def self.selectOneNxDirectory3OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(NxDirectory3::directories(), lambda{|obj| obj["description"] })
    end

    # NxDirectory3::landing(directory)
    def self.landing(directory)
        loop {

            system("clear")

            puts NxDirectory3::toString(directory).green

            puts "uuid: #{directory["uuid"]}"

            puts ""
            
            NxDirectory3::getDx3ElementsLocationsFromDisk(directory["uuid"]).each{|location|
                puts "- #{File.basename(location)}"
            }

            puts ""

            connected = []

            Links::entities(directory["uuid"])
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
                folderpath = Utils::locationByUniqueStringOrNull(directory["uuid"])
                if folderpath then
                    system("open '#{folderpath}'")
                else
                    puts "Interestingly I could not find the location for directory #{directory}"
                    LucilleCore::pressEnterToContinue()
                end
            end

            if Interpreting::match("connect", command) then
                NyxEntities::linkToOtherArchitectured(directory)
            end

            if Interpreting::match("disconnect", command) then
                NyxEntities::unlinkFromOther(directory)
            end
        }
    end

    # NxDirectory3::nx19s()
    def self.nx19s()
        NxDirectory3::directories()
            .map{|directory|
                volatileuuid = SecureRandom.hex[0, 8]
                nx19 = {
                    "announce" => "#{volatileuuid} #{NxDirectory3::toString(directory).gsub("[Directory3]", "[Dx3 ]")}",
                    "type"     => "NxDirectory3",
                    "payload"  => directory
                }

                [nx19] + NxDirectory3::getDx3ElementsLocationsFromDisk(directory["uuid"]).map{|location|
                    directoryElement = {
                        "uuid"        => SecureRandom.hex,
                        "entityType"  => "NxDirectory3Element",
                        "datetime"    => Time.new.utc.iso8601,
                        "parentuuid"  => directory["uuid"],
                        "description" => File.basename(location)
                    }
                    volatileuuid = SecureRandom.hex[0, 8]
                    {
                        "announce" => "#{volatileuuid} #{NxDirectory3::toString(directory)} / #{directoryElement["description"]}",
                        "type"     => "NxDirectory3Element",
                        "payload"  => directoryElement
                    }
                }
            }
            .flatten
    end
end
