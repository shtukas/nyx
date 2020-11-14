
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        NyxObjects2::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # --------------------------------------------------

    # Quarks::issueLine(line)
    def self.issueLine(line)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonfilename)
        LeptonsFunctions::createLeptonLine(leptonfilepath, line)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quarks::issueUrl(url)
    def self.issueUrl(url)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonfilename)
        LeptonsFunctions::createLeptonUrl(leptonfilepath, url)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quarks::issueAionFileSystemLocation(aionFileSystemLocation)
    def self.issueAionFileSystemLocation(aionFileSystemLocation)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonfilename)
        LeptonsFunctions::createLeptonAionFileSystemLocation(leptonfilepath, aionFileSystemLocation)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quarks::interactivelyIssueQuarkOrNull()
    def self.interactivelyIssueQuarkOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "url", "aion-point"])
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return Quarks::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            quark = Quarks::issueUrl(url)
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            Quarks::setDescription(quark, description)
            return quark
        end
        if type == "aion-point" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
            aionFileSystemLocation = "/Users/pascal/Desktop/#{locationname}"
            quark = Quarks::issueAionFileSystemLocation(aionFileSystemLocation)
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            Quarks::setDescription(quark, description)
            return quark
        end
        nil
    end

    # --------------------------------------------------

    # Quarks::setDescription(quark, description)
    def self.setDescription(quark, description)
        filename = object["leptonfilename"]
        filepath = LeptonsFunctions::leptonFilenameToFilepath(filename)
        LeptonsFunctions::setDescription(filepath, description)
    end

    # Quarks::toString(quark)
    def self.toString(quark)
        leptonfilename = quark["leptonfilename"]
        leptonFilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonfilename)
        description = LeptonsFunctions::getDescription(leptonFilepath)
        "[quark] #{description}"
    end

    # Quarks::getTypeOrNull(quark)
    def self.getTypeOrNull(quark)
        filename = quark["leptonfilename"]
        filepath = LeptonsFunctions::leptonFilenameToFilepath(filename)
        LeptonsFunctions::getTypeOrNull(filepath)
    end

    # --------------------------------------------------

    # Quarks::access(quark)
    def self.access(quark)
        puts "access: #{Quarks::toString(quark)}"
        filepath = LeptonsFunctions::leptonFilenameToFilepath(quark["leptonfilename"])
        type = LeptonsFunctions::getTypeOrNull(filepath)
        if type == "line" then
            puts LeptonsFunctions::getTypeLineLineOrNull(filepath)
            LucilleCore::pressEnterToContinue()
            return
        end
        if type == "url" then
            url = LeptonsFunctions::getTypeUrlUrlOrNull(filepath)
            puts url
            system("open '#{url}'")
            return
        end
        if type == "aion-location" then
            leptonFilename = quark["leptonfilename"]
            leptonFilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonFilename)
            operator = ElizabethLeptons.new(leptonFilepath)
            nhash = LeptonsFunctions::getTypeAionLocationRootHashOrNull(leptonFilepath)
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
            puts "aion point exported"
            LucilleCore::pressEnterToContinue()
            return
        end
        raise "error: c9b7f9a2-c0d0-4a86-add8-3ca411b8c240"
    end

    # Quarks::destroyQuarkAndLepton(quark)
    def self.destroyQuarkAndLepton(quark)
        leptonfilename = quark["leptonfilename"]
        leptonfilepath = LeptonsFunctions::leptonFilenameToFilepath(leptonfilename)
        puts "deleting file: #{leptonfilepath}"
        FileUtils.rm(leptonfilepath)
        puts "deleting quark:"
        puts JSON.pretty_generate(quark)
        NyxObjects2::destroy(quark)
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if NyxObjects2::getOrNull(quark["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "filename: #{quark["leptonfilename"]}".yellow
            puts "filepath: #{LeptonsFunctions::leptonFilenameToFilepath(quark["leptonfilename"])}".yellow

            puts ""

            sources = Arrows::getSourcesForTarget(quark)
            sources.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            puts ""

            Arrows::getTargetsForSource(quark).each{|target|
                menuitems.item(
                    "target: #{GenericNyxObject::toString(target)}",
                    lambda { GenericNyxObject::landing(target) }
                )
            }

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::access(quark) }
            )

            mx.item("set/update description".yellow, lambda {
                leptonfilename = LeptonsFunctions::leptonFilenameToFilepath(quark["leptonfilename"])
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                LeptonsFunctions::setDescription(leptonfilename, description)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("add tag".yellow, lambda {
                set = Tags::selectExistingTagOrMakeNewOneOrNull()
                return if set.nil?
                Arrows::issueOrException(set, quark)
            })

            mx.item("add to listing".yellow, lambda {
                listing = Listings::extractionSelectListingOrMakeListingOrNull()
                return if listing.nil?
                Arrows::issueOrException(listing, quark)
            })

            mx.item("remove from parent".yellow, lambda {
                parents = Arrows::getSourcesForTarget(quark)
                parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", parents, lambda { |xnode| GenericNyxObject::toString(parent) })
                return if parent.nil?
                Arrows::unlink(parent, quark)
            })

            mx.item(
                "destroy".yellow,
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("are you sure you want to destroy this quark ? ") then
                        Quarks::destroyQuarkAndLepton(quark)
                    end
                }
            )

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
