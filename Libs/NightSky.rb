
# encoding: UTF-8

class NightSky

    # ------------------------------------
    # Utils

    # NightSky::isNyxNode(filepath)
    def self.isNyxNode(filepath)
        File.basename(filepath)[-8, 8] == ".nyxnode"
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
            next if !NightSky::isNyxNode(filepath)
            node = NxNode.new(filepath)
            return filepath if node.uuid() == uuid
            # We haven't yet found the ordinal that we are looking for but we are going to
            # make sure we remember what we have learnt just there, for future reference
            XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{node.uuid()}", filepath)
        }
        nil
    end

    # ------------------------------------
    # Makers

    # NightSky::spawn(uuid, description, locationdirective)
    def self.spawn(uuid, description, locationdirective)

        filepath = (lambda { |locationdirective|
            if locationdirective == "nest" then
                filename = "#{SecureRandom.hex(5)}.nyxnode"
                folder1 = LucilleCore::indexsubfolderpath(Config::pathToNest(), 100)
                return "#{folder1}/#{filename}"
            end
            if locationdirective == "desktop" then
                filename = "#{CommonUtils::sanitiseStringForFilenaming(description)}-#{SecureRandom.hex(2)}.nyxnode"
                return "#{Config::pathToDesktop()}/#{filename}"
            end
            raise "(error 6e423c07-c897-44ef-a27c-71c285b4b6da) unsupported location directive"
        }).call(locationdirective)

        taxonomy = NightSky::selectOneTaxonomyOrNull()

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table orbital (_key_ text primary key, _collection_ text, _data_ blob)", [])
        db.close
        node = NxNode.new(filepath)
        node.set("uuid", uuid)
        node.set("unixtime", Time.new.to_i)
        node.set("datetime", Time.new.utc.iso8601)
        node.set("description", description)

        if taxonomy then
            node.set("taxonomy", taxonomy)
        end

        NightSkyIndex::add_uuid_to_index(node.uuid())
        
        XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}", filepath)

        node
    end

    # NightSky::interactivelyIssueNewNxNodeNull() # nil or node
    def self.interactivelyIssueNewNxNodeNull()
        puts "> create a new nyx node"
        locationdirectives = ["nest", "desktop"]
        locationdirective = LucilleCore::selectEntityFromListOfEntitiesOrNull("location", locationdirectives)
        return nil if locationdirective.nil?
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        NightSky::spawn(uuid, description, locationdirective)
    end

    # ------------------------------------
    # Data

    # NightSky::getOrNull(uuid)
    def self.getOrNull(uuid)
        filepath = XCache::getOrNull("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}")
        if filepath then
            if File.exist?(filepath) and NightSky::isNyxNode(filepath) then
                node = NxNode.new(filepath)
                if node.uuid() == uuid then
                    return node
                end
            end
        end

        puts "> locate node #{uuid} (use the force)"
        filepath = NightSky::locateOrbitalByUUIDOrNull_UseTheForce(uuid)

        if filepath.nil? then
            puts "> I could not locate uuid: #{uuid}"
            puts "> Going to remove it from the Index"
            LucilleCore::pressEnterToContinue()
            NightSkyIndex::remove_uuid_from_index(uuid)
            return nil
        end

        XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{uuid}", filepath)

        NxNode.new(filepath)
    end

    # NightSky::nodeuuidsFromIndex()
    def self.nodeuuidsFromIndex()
        LucilleCore::locationsAtFolder(Config::pathToNightSkyIndex())
            .select{|filepath| filepath[0, 1] != "." }
            .map{|filepath| IO.read(filepath).strip }
    end

    # NightSky::nodes()
    def self.nodes()
        NightSky::nodeuuidsFromIndex()
            .map{|uuid| NightSky::getOrNull(uuid) }
            .compact
    end

    # NightSky::nodeEnumeratorFromFSEnumeration()
    def self.nodeEnumeratorFromFSEnumeration()
        Enumerator.new do |nodes|
            NightSky::galaxyFilepathEnumerator().each{|filepath|
                next if !NightSky::isNyxNode(filepath)
                node = NxNode.new(filepath)
                XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{node.uuid()}", filepath)
                nodes << node
            }
        end
    end

    # NightSky::taxonomies()
    def self.taxonomies()
        [
            "Person", "Geolocation", "Entity", 
            "Documentation", "Concept", "Technology", "Organization", 
            "Commercial Company",
            "Event",
            "News (Article/Video); Documentary",
            "Quote",
            "Pascal Brain Dump",
            "Misc."
        ]
    end

    # NightSky::selectOneTaxonomyOrNull()
    def self.selectOneTaxonomyOrNull()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("taxonomy", NightSky::taxonomies())
    end

    # ------------------------------------
    # Operations

    # NightSky::fs_scan()
    def self.fs_scan()
        nodeuuids = NightSky::nodeuuidsFromIndex()
        NightSky::galaxyFilepathEnumerator().each{|filepath|
            next if !NightSky::isNyxNode(filepath)
            puts "fs scan: #{filepath}"
            node = NxNode.new(filepath)
            XCache::set("f1e45aa7-db4d-40d3-bb57-d7c9ca02c1bb:#{node.uuid()}", filepath)
            next if nodeuuids.include?(node.uuid())
            NightSkyIndex::add_uuid_to_index(node.uuid())
            nodeuuids << node.uuid()
        }
    end

    # NightSky::link(node1, node2)
    def self.link(node1, node2)
        node1.linkeduuids_add(node2.uuid())
        node2.linkeduuids_add(node1.uuid())
    end

    # NightSky::landing(node) # nil or node
    # This function is originally used as action, a landing, but can also return the node
    # when the user issues "fox", and this matters during a fox search
    def self.landing(node)
        loop {

            system('clear')

            puts node.description().green
            puts "- uuid: #{node.uuid()}"
            puts "- filepath : #{node.filepath()}"
            puts "- taxonomy: #{node.get("taxonomy")}"

            store = ItemStore.new()

            coredatarefs = node.coredatarefs()
            if coredatarefs.size > 0 then
                puts ""
                puts "coredatarefs:"
                coredatarefs.each{|ref|
                    store.register(ref, false)
                    puts "(#{store.prefixString()}) #{CoreDataRefs::toString(ref)}"
                }
            end

            notes = node.notes()
            if notes.size > 0 then
                puts ""
                puts "notes:"
                notes.each{|note|
                    store.register(note, false)
                    puts "(#{store.prefixString()}) #{note["line"]}"
                }
            end

            linkednodes = node.linked_nodes()
            if linkednodes.size > 0 then
                puts ""
                linkednodes
                    .each{|linkednode|
                        store.register(linkednode, false)
                        puts "(#{store.prefixString()}) #{linkednode.description()}"
                    }
            end

            puts ""
            puts "commands: description | access | link | coredata | note | select | out nest | envelop | destroy"

            if node.get("taxonomy").nil? then
                puts "> taxonomy not found, let's set one:"
                taxonomy = NightSky::selectOneTaxonomyOrNull()
                if taxonomy then
                    node.set("taxonomy", taxonomy)
                end
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                item = store.get(indx)
                next if item.nil?
                if item.class.to_s == "NxNode" then
                    o = NightSky::landing(item)
                    if o then
                        return o
                    end
                    next
                end
                if item["mikuType"] == "NxNote" then
                    NxNote::landing(item)
                end
                if item["mikuType"] == "CoreDataRef" then
                    CoreDataRefs::landing(item, node)
                end
                next
            end

            if command == "description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                next if description == ""
                node.description_set(description)
                next
            end

            if command == "access" then
                coredatarefs = node.coredatarefs()
                if coredatarefs.empty? then
                    puts "This node doesn't have any payload"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                if coredatarefs.size == 1 then
                    CoreDataRefs::access(coredatarefs.first, node)
                    next
                end
                coredataref = LucilleCore::selectEntityFromListOfEntitiesOrNull("ref", coredatarefs, lambda{|ref| CoreDataRefs::toString(ref) })
                next if coredataref.nil?
                CoreDataRefs::access(coredataref, node)
                next
            end

            if command == "link" then
                node2 = NightSky::architectOrbitalOrNull()
                if node2 then
                    NightSky::link(node, node2)
                    o = NightSky::landing(node2)
                    if o then
                        return o
                    end
                end
                next
            end

            if command == "coredata" then
                coredataref = CoreDataRefs::interactivelyMakeNewReferenceOrNull(node)
                if coredataref then
                    node.coredataref_add(coredataref)
                end
                next
            end

            if command == "out nest" then
                if !node.filepath().start_with?(Config::pathToNest()) then
                    puts "You con only out nest node that are in the nest. This node is currently at: #{node.filepath()}"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                node.move_to_desktop()
                next
            end

            if command == "envelop" then
                if node.filepath().start_with?(Config::pathToNest()) then
                    puts "You are in the nest, this node doesn't have an envelop per se"
                    LucilleCore::pressEnterToContinue()
                    next
                end
                system("open '#{File.dirname(node.filepath())}'")
                next
            end

            if command == "select" then
                return node
            end

            if command == "destroy" then
                puts "> request to destroy nyx node: #{node.description()}"
                code = LucilleCore::askQuestionAnswerAsString("Enter node uuid: ")
                if code == node.uuid() then
                    if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction: ") then
                        NightSkyIndex::remove_uuid_from_index(node.uuid())
                        FileUtils.rm(node.filepath())
                        return
                    end
                end
            end

            if command == "note" then
                note = NxNote::makeNoteOrNull()
                next if note.nil?
                node.note_add(note)
            end
        }

        nil
    end

    # NightSky::interactivelySelectOrbitalOrNull()
    def self.interactivelySelectOrbitalOrNull()
        NightSky::select()
    end

    # NightSky::architectOrbitalOrNull()
    def self.architectOrbitalOrNull()
        options = ["select || new", "new"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "select || new" then
            node = NightSky::interactivelySelectOrbitalOrNull()
            if node then
                return node
            end
            return NightSky::interactivelyIssueNewNxNodeNull()
        end
        if option == "new" then
            return NightSky::interactivelyIssueNewNxNodeNull()
        end
        nil
    end

    # NightSky::nx20s() # Array[Nx20]
    def self.nx20s()
        NightSky::nodes()
            .map{|node|
                [
                    {
                        "announce" => node.description(),
                        "unixtime" => node.unixtime(),
                        "node"     => node
                    },
                    {
                        "announce" => node.uuid(),
                        "unixtime" => node.unixtime(),
                        "node"     => node
                    }
                ]
            }
            .flatten
    end

    # NightSky::search()
    def self.search()
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
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["announce"] })
                break if nx20.nil?
                NightSky::landing(nx20["node"])
            }
        }
        nil
    end

    # NightSky::select() nil or node
    def self.select()
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
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", nx20s, lambda{|i| i["announce"] })
                if nx20 then
                    node = nx20["node"]
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["return '#{node.description()}'", "landing on '#{node.description()}'"])
                    next if nx20.nil?
                    if option == "return '#{node.description()}'" then
                        return node
                    end
                    if option == "landing on '#{node.description()}'" then
                        o = NightSky::landing(node)
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
