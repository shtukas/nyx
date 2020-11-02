
# encoding: UTF-8

class NGX15

    # NGX15::datapoints()
    def self.datapoints()
        NyxObjects2::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # NGX15::issueNGX15(code)
    def self.issueNGX15(code)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "NGX15",
            "ngx15"      => code
        }
        NyxObjects2::put(object)
        object
    end

    # NGX15::issueNewNGX15InteractivelyOrNull()
    def self.issueNewNGX15InteractivelyOrNull()
        op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["location already exists", "issue new location name"])
        return nil if op.nil?
        if op == "location already exists" then
            code = LucilleCore::askQuestionAnswerAsString("code name: ")
            return nil if code.size == 0
        end
        if op == "issue new location name" then
            code = "NGX15-#{SecureRandom.uuid}"
            puts "code: #{code}"
            LucilleCore::pressEnterToContinue()
        end
        NGX15::issueNGX15(code)
    end

    # NGX15::toString(datapoint)
    def self.toString(datapoint)
        if datapoint["description"] then
            return "[#{datapoint["type"]}] #{datapoint["description"]} ( #{datapoint["ngx15"]} )"
        end
        "[#{datapoint["type"]}] #{datapoint["ngx15"]}"
    end

    # NGX15::openNGX15(datapoint)
    def self.openNGX15(datapoint)
        location = GalaxyFinder::uniqueStringToLocationOrNull(datapoint["ngx15"])
        if location then
            puts "target file '#{location}'"
            system("open '#{File.dirname(location)}'")
            LucilleCore::pressEnterToContinue()
        else
            puts "I could not determine the location of #{datapoint["ngx15"]}"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NGX15::landing(datapoint)
    def self.landing(datapoint)
        loop {

            return if NyxObjects2::getOrNull(datapoint["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts ""

            puts NGX15::toString(datapoint).green
            puts "uuid: #{datapoint["uuid"]}".yellow
            puts "date: #{GenericNyxObject::getObjectReferenceDateTime(datapoint)}".yellow

            puts ""

            mx.item(
                "open".yellow,
                lambda {
                    NGX15::openNGX15(datapoint)
                }
            )

            mx.item("set/update description".yellow, lambda {
                description = Miscellaneous::editTextSynchronously(datapoint["description"] || "").strip
                return if description == ""
                datapoint["description"] = description
                NyxObjects2::put(datapoint)
            })

            mx.item("set/update datetime".yellow, lambda {
                datetime = Miscellaneous::editTextSynchronously(datapoint["referenceDateTime"] || Time.new.utc.iso8601).strip
                datapoint["referenceDateTime"] = datetime
                NyxObjects2::put(datapoint)
            })

            mx.item("add to set".yellow, lambda {
                set = Tags::selectExistingTagOrMakeNewOneOrNull()
                return if set.nil?
                Arrows::issueOrException(set, datapoint)
            })

            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{NGX15::toString(datapoint)}': ") then
                    NGX15::datapointTerminationProtocolReturnBoolean(datapoint)
                end
            })

            puts ""

            source = Arrows::getSourcesForTarget(datapoint)
            source.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            puts ""

            Arrows::getTargetsForSource(datapoint).each{|target|
                menuitems.item(
                    "target: #{GenericNyxObject::toString(target)}",
                    lambda { GenericNyxObject::landing(target) }
                )
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NGX15::datapointTerminationProtocolReturnBoolean(datapoint)
    def self.datapointTerminationProtocolReturnBoolean(datapoint)

        puts "Destroying datapoint: #{NGX15::toString(datapoint)}"

        location = GalaxyFinder::uniqueStringToLocationOrNull(datapoint["ngx15"])
        if location then
            puts "Target file '#{location}'"
            puts "Delete as appropriate"
            system("open '#{File.dirname(location)}'")
            LucilleCore::pressEnterToContinue()
        else
            puts "I could not determine the location of #{datapoint["ngx15"]}"
            if !LucilleCore::askQuestionAnswerAsBoolean("Continue with datapoint deletion ? ") then
                return
            end
        end

        NyxObjects2::destroy(datapoint)

        true
    end
end
