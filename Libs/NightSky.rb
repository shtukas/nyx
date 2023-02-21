
# encoding: UTF-8

# NightSky keep track of the NxOrbital, that are the nodes of the Nyx network

class NightSky

    # ------------------------------------
    # Utils

    # NightSky::isOrbital(filepath)
    def self.isOrbital(filepath)
        File.basename(filepath).include?(".nyx-orbital.")
    end

    # NightSky::filenameComponentsOrNull(filename)
    # "1main0.nyx-orbital.12345678"
    # {"main"=>"1main0", "suffix"=>"12345678"}
    def self.filenameComponentsOrNull(filename)
        return nil if !filename.include?(".nyx-orbital.")
        p1 = filename.index(".nyx-orbital.")
        s1 = filename[0, p1]
        s2 = filename[p1+13, filename.size]
        {
            "main"   => s1,
            "suffix" => s2
        }
    end

    # NightSky::galaxyFilepathEnumerator()
    def self.galaxyFilepathEnumerator()
        roots = ["#{Config::userHomeDirectory()}/Desktop", "#{Config::userHomeDirectory()}/Galaxy"]
        Enumerator.new do |filepaths|
            roots.each{|root|
                if File.exist?(root) then
                    begin
                        Find.find(root) do |path|
                            filepaths << path
                        end
                    rescue
                    end
                end
            }
        end
    end

    # NightSky::locateOrbitalByUUIDOrNull_UseTheForce(uuid)
    def self.locateOrbitalByUUIDOrNull_UseTheForce(uuid)
        NightSky::galaxyFilepathEnumerator().each{|filepath|
            next if !NightSky::isOrbital(filepath)
            orbital = NxOrbital.new(filepath)
            return filepath if orbital.uuid() == uuid
            # We haven't yet found the ordinal that we are looking for but we are going to
            # make sure we remember what we have learnt just there, for future reference
            XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{orbital.uuid()}", filepath)
        }
    end

    # ------------------------------------
    # Makers

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

    # NightSky::interactivelyIssueNewNxOrbitalNull()
    def self.interactivelyIssueNewNxOrbitalNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(uuid)
        NightSky::spawn(uuid, description, coredataref)
    end

    # ------------------------------------
    # Data

    # NightSky::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = XCache::getOrNull("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}")
        if filepath then
            if File.exist?(filepath) then
                orbital = NxOrbital.new(filepath)
                if orbital.uuid() == uuid then
                    return orbital
                end
            end
        end

        puts "> locate orbital use the force: #{uuid}"
        filepath = NightSky::locateOrbitalByUUIDOrNull_UseTheForce(uuid)

        if filepath then
            XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}", filepath)
        end

        filepath
    end

    # NightSky::ordinaluuids()
    def self.ordinaluuids()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NightSky")
            .select{|filepath| filepath[0, 1] != "." }
            .map{|filepath| IO.read(filepath).strip }
    end

    # NightSky::orbitals()
    def self.orbitals()
        NightSky::ordinaluuids()
            .map{|uuid| NightSky::getOrNull(uuid) }
            .compact
    end

    # ------------------------------------
    # Operations

    # NightSky::fs_scan()
    def self.fs_scan()
        orbitaluuids = NightSky::ordinaluuids()
        NightSky::galaxyFilepathEnumerator().each{|filepath|
            next if !NightSky::isOrbital(filepath)
            puts "fs scan: #{filepath}"
            orbital = NxOrbital.new(filepath)
            XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{orbital.uuid()}", filepath)
            next if orbitaluuids.include?(orbital.uuid())
            File.open("#{Config::pathToDataCenter()}/NightSky/#{CommonUtils::timeStringL22()}", "w"){|f|
                f.write(orbital.uuid())
            }
            orbitaluuids << orbital.uuid()
        }
    end

    # NightSky::link(orbital1, orbital2)
    def self.link(orbital1, orbital2)
        orbital1.linkeduuids_add(orbital2.uuid())
        orbital2.linkeduuids_add(orbital1.uuid())
    end

    # NightSky::landing(orbital)
    def self.landing(orbital)
        loop {

            system('clear')

            puts orbital.toString()
            puts "> uuid: #{orbital.uuid()}"
            puts "> coredataref: #{orbital.coredataref()}"

            store = ItemStore.new()

            puts ""
            orbital
                .linked_orbitals()
                .each{|linkedorbital|
                    store.register(linkedorbital, false)
                    puts "#{store.prefixString()}: #{linkedorbital.toString()}"
                }

            puts ""
            puts "commands: access | link | coredata | move to desktop"

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
                    NightSky::link(orbital, orbital2)
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

            if command == "move to desktop" then
                orbital.move_to_desktop()
                break
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
    def self.architectOrbitalOrNull()
        options = ["select || new", "new"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "select || new" then
            orbital = NightSky::interactivelySelectOrbitalOrNull()
            if orbital then
                return orbital
            end
            return NightSky::interactivelyIssueNewNxOrbitalNull()
        end
        if option == "new" then
            return NightSky::interactivelyIssueNewNxOrbitalNull()
        end
        nil
    end
end
