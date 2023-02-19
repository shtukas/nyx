
# encoding: UTF-8

# NightSky keep track of the NxOrbital, that are the nodes of the Nyx network

class NightSky

    # NightSky::spawn(uuid, description, coredataref)
    def self.spawn(uuid, description, coredataref)
        filename = "#{SecureRandom.hex(5)}.nyx-orbital.#{SecureRandom.hex(5)}"
        filepath = "#{Config::pathToGalaxy()}/Nyx/Orbitals/#{filename}"
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table orbital (_key_ text primary key, _collection_ text, _data_ blob)", [])
        db.close
        orbital = NxOrbital.new(filepath)
        orbital.set("uuid", uuid)
        orbital.set("unixtime", Time.new.to_i)
        orbital.set("datetime", Time.new.utc.iso8601)
        orbital.set("description", description)
        orbital.set("coredataref", coredataref)
        orbital
    end

    # NightSky::orbitals()
    def self.orbitals()
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/Nyx/Orbitals")
            .select{|filepath| filepath.include?(".nyx-orbital.") }
            .map{|filepath| NxOrbital.new(filepath) }
    end

    # NightSky::getOrNull(uuid)
    def self.getOrNull(uuid)
        LucilleCore::locationsAtFolder("#{Config::pathToGalaxy()}/Nyx/Orbitals")
        .select{|filepath| filepath.include?(".nyx-orbital.") }
        .each{|filepath|
            orbital = NxOrbital.new(filepath)
            if orbital.uuid() == uuid then
                return orbital
            end
        }
        nil
    end

    # NightSky::interactivelyIssueNewNxOrbitalNull()
    def self.interactivelyIssueNewNxOrbitalNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        NightSky::spawn(uuid, description, coredataref)
    end

    # NightSky::landing(orbital)
    def self.landing(orbital)
        loop {

            system('clear')

            puts orbital.toString()
            puts "> coredataref: #{orbital.coredataref()}"

            store = ItemStore.new()

            puts ""
            linked = NxLinks::linkedorbitals(orbital.uuid())
            linked.each{|linkedorbital|
                store.register(linkedorbital, false)
                puts "- (#{store.prefixString()}) #{linkedorbital.toString()}"
            }

            puts ""
            puts "commands: access | link | coredata"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                linkedorbital = store.get(indx)
                next if linkedorbital.nil?
                NightSky::landing(linkedorbital)
                next
            end

            if command == "access" then
                if orbital.coredataref().nil? then
                    puts "This nyx node doesn't have a coredataref"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                CoreData::access(orbital.coredataref())
                next
            end

            if command == "link" then
                orbital2 = NightSky::architectOrbitalOrNull()
                if orbital2 then
                    NxLinks::link(orbital.uuid(), orbital2.uuid())
                    NightSky::landing(orbital2)
                end
                next
            end

            if command == "coredata" then
                next if !LucilleCore::askQuestionAnswerAsBoolean("Confirm update of CoreData payload ? ", true)
                coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(orbital.uuid())
                orbital.coredataref_set(coredataref)
                next
            end
        }
    end

    # NightSky::interactivelySelectOrbitalOrNull()
    def self.interactivelySelectOrbitalOrNull()
        # This function is going to evolve as we get more nodes, but it's gonna do for the moment
        orbitals = NightSky::orbitals()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("orbitals", orbitals, lambda{|orbital| orbital.toString() })
    end

    # NightSky::architectOrbitalOrNull()
    def self.architectNodeOrNull()
        options = ["select || new", "new"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "select || new" then
            orbital = NightSky::interactivelySelectOrbitalOrNull()
            if orbital then
                return orbital
            end
            return NightSky::interactiveSpawn()
        end
        if option == "new" then
            return NightSky::interactiveSpawn()
        end
        nil
    end

end
