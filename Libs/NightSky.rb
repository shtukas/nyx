
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
        XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}", filepath)
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
        orbital = NightSky::spawn(uuid, description, nil)
        coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(orbital)
        if coredataref then
            orbital.coredataref_set(coredataref)
        end
        orbital
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

        return nil if filepath.nil?

        XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}", filepath)

        NxOrbital.new(filepath)
    end

    # NightSky::ordinaluuids()
    def self.ordinaluuids()
        LucilleCore::locationsAtFolder(Config::pathToNightSkyIndex())
            .select{|filepath| filepath[0, 1] != "." }
            .map{|filepath| IO.read(filepath).strip }
    end

    # NightSky::orbitals()
    def self.orbitals()
        NightSky::ordinaluuids()
            .map{|uuid| NightSky::getOrNull(uuid) }
            .compact
    end

    # NightSky::orbitalEnumeratorFromFSEnumeration()
    def self.orbitalEnumeratorFromFSEnumeration()
        Enumerator.new do |orbitals|
            NightSky::galaxyFilepathEnumerator().each{|filepath|
                next if !NightSky::isOrbital(filepath)
                orbital = NxOrbital.new(filepath)
                XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{orbital.uuid()}", filepath)
                orbitals << orbital
            }
        end
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
            File.open("#{Config::pathToNightSkyIndex()}/#{CommonUtils::timeStringL22()}", "w"){|f|
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

    # NightSky::landing(orbital) # nil or orbital
    # This function is originally used as action, a landing, but can also return the orbital
    # when the user issues "fox", and this matters during a fox search
    def self.landing(orbital)
        loop {

            system('clear')

            puts orbital.description()
            puts "> filepath: #{orbital.filepath()}"
            puts "> uuid: #{orbital.uuid()}"
            puts "> coredataref: #{orbital.coredataref()}"
            if orbital.companion_directory_or_null() then
                puts "> companion directory: #{orbital.companion_directory_or_null()}"
            end

            store = ItemStore.new()

            puts ""
            orbital
                .linked_orbitals()
                .each{|linkedorbital|
                    store.register(linkedorbital, false)
                    puts "#{store.prefixString()}: #{linkedorbital.description()}"
                }

            puts ""
            puts "commands: access | link | coredata | move to desktop | fox"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                linkedorbital = store.get(indx)
                next if linkedorbital.nil?
                o = NightSky::landing(linkedorbital)
                if o then
                    return o
                end
                next
            end

            if command == "access" then
                if orbital.coredataref().nil? then
                    puts "This nyx node doesn't have a coredataref"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                CoreData::access(orbital.coredataref(), orbital)
                next
            end

            if command == "link" then
                orbital2 = NightSky::architectOrbitalOrNull()
                if orbital2 then
                    NightSky::link(orbital, orbital2)
                    o = NightSky::landing(orbital2)
                    if o then
                        return o
                    end
                end
                next
            end

            if command == "coredata" then
                next if !LucilleCore::askQuestionAnswerAsBoolean("Confirm update of CoreData payload ? ", true)
                coredataref = CoreData::interactivelyMakeNewReferenceStringOrNull(orbital)
                orbital.coredataref_set(coredataref)
                next
            end

            if command == "move to desktop" then
                orbital.move_to_desktop()
                break
            end

            if command == "fox" then
                return orbital
            end
        }

        nil
    end

    # NightSky::interactivelySelectOrbitalOrNull()
    def self.interactivelySelectOrbitalOrNull()
        # This function is going to evolve as we get more nodes, but it's gonna do for the moment
        orbitals = NightSky::orbitals()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("orbitals", orbitals, lambda{|orbital| orbital.description() })
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

    # NightSky::nx20s() # Array[Nx20]
    def self.nx20s()
        NightSky::orbitals()
            .map{|orbital|
                {
                    "announce" => orbital.description(),
                    "unixtime" => orbital.unixtime(),
                    "orbital"  => orbital
                }
            }
    end

    # NightSky::search_action()
    def self.search_action()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = NightSky::nx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = NightSky::nx20s()
                                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                                .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                NightSky::landing(nx20["orbital"])
            }
        }
        nil
    end

    # NightSky::search_fox() nil or ordinal
    def self.search_fox()
        puts "> entering fox search"
        LucilleCore::pressEnterToContinue()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            if fragment == "" then
                if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                    next
                else
                    return nil
                end
            else
                # continue
            end

            nx20s = NightSky::nx20s()
                            .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }

            if nx20s.size > 0 then
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("orbital", nx20s, lambda{|i| i["announce"] })
                if nx20 then
                    orbital = nx20["orbital"]
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["return '#{orbital.description()}'", "landing on '#{orbital.description()}'"])
                    next if nx20.nil?
                    if option == "return '#{orbital.description()}'" then
                        return orbital
                    end
                    if option == "landing on '#{orbital.description()}'" then
                        o = NightSky::landing(orbital)
                        if o then
                            return o
                        end
                    end
                else
                    if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                        next
                    else
                        return nil
                    end
                end
            else
                if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                    next
                else
                    return nil
                end
            end
        }
        nil
    end

end
