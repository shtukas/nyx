
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        NyxObjects2::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # --------------------------------------------------

    # Quarks::issueLine(line)
    def self.issueLine(line)
        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "type"              => "line"
        }
        NyxObjects2::put(object)
        object
    end

    # Quarks::issueUrl(url)
    def self.issueUrl(url)
        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "type"              => "url"
        }
        NyxObjects2::put(object)
        object
    end

    # Quarks::issueAionFileSystemLocation(aionFileSystemLocation)
    def self.issueAionFileSystemLocation(aionFileSystemLocation)
        operator = ElizabethX2.new()
        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "type"              => "aion-location",
            "roothash"          => AionCore::commitLocationReturnHash(operator, aionFileSystemLocation)
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
        quark["description"] = description
        NyxObjects2::put(quark)
        quark
    end

    # Quarks::toString(quark)
    def self.toString(quark)
        if quark["description"] then
            return "[quark] #{quark["description"]}"
        end
        if quark["type"] == "line" then
            return "[quark] #{quark["line"]}"
        end
        if quark["type"] == "url" then
            return "[quark] #{quark["url"]}"
        end
        if quark["type"] == "aion-location" then
            operator = ElizabethX2.new()
            aionobject = AionCore::getAionObjectByHash(operator, quark["roothash"])
            description = aionobject["name"]
            return "[quark] #{description}"
        end
        puts quark
        raise "error: 963c91c2-1370-4807-8d89-96c9065de3ea"
    end

    # --------------------------------------------------

    # Quarks::open1(quark)
    def self.open1(quark)
        puts "opening: #{Quarks::toString(quark)}"

        type = quark["type"]
        if type == "line" then
            puts quark["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if type == "url" then
            url = quark["url"]
            puts url
            system("open '#{url}'")
            return
        end
        if type == "aion-location" then
            operator = ElizabethX2.new()
            nhash = quark["roothash"]
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
            puts "aion point exported"
            LucilleCore::pressEnterToContinue()
            return
        end
        raise "error: c9b7f9a2-c0d0-4a86-add8-3ca411b8c240"
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if NyxObjects2::getOrNull(quark["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow

            puts ""

            Patricia::getAllParentingPathsOfSize2(quark).each{|item|
                announce = "#{Patricia::toString(item["p1"])} <- #{item["p2"] ? Patricia::toString(item["p2"]) : ""}"
                mx.item(
                    "source: #{announce}",
                    lambda { Patricia::landing(item["p1"]) }
                )
            }

            puts ""

            Arrows::getTargetsForSource(quark).each{|target|
                menuitems.item(
                    "target: #{Patricia::toString(target)}",
                    lambda { Patricia::landing(target) }
                )
            }

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::open1(quark) }
            )

            mx.item("set/update description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                Quarks::setDescription(quark, description)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("add parent".yellow, lambda {
                o1 = Patricia::architect()
                return if o1.nil?
                Arrows::issueOrException(o1, quark)
            })

            mx.item("remove parent".yellow, lambda {
                parents = Arrows::getSourcesForTarget(quark)
                parent = LucilleCore::selectEntityFromListOfEntitiesOrNull("parent", parents, lambda { |px| Patricia::toString(px) })
                return if parent.nil?
                Arrows::unlink(parent, quark)
            })

            mx.item(
                "destroy".yellow,
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("are you sure you want to destroy this quark ? ") then
                        NyxObjects2::destroy(quark)
                    end
                }
            )

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
