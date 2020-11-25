
# encoding: UTF-8

class NGX15

    # NGX15::ngx15s()
    def self.ngx15s()
        NyxObjects2::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # NGX15::issueNGX15(code)
    def self.issueNGX15(code)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
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

    # NGX15::toString(ngx15)
    def self.toString(ngx15)
        if ngx15["description"] then
            return "[NGX15] #{ngx15["description"]}"
        end
        "[NGX15] #{ngx15["ngx15"]}"
    end

    # NGX15::openNGX15(ngx15)
    def self.openNGX15(ngx15)
        location = GalaxyFinder::uniqueStringToLocationOrNull(ngx15["ngx15"])
        if location then
            puts "target file '#{location}'"
            if File.file?(location) then
                system("open '#{File.dirname(location)}'")
            else
                system("open '#{location}'")
            end
            LucilleCore::pressEnterToContinue()
        else
            puts "I could not determine the location of #{ngx15["ngx15"]}"
            LucilleCore::pressEnterToContinue()
        end
    end

    # NGX15::landing(ngx15)
    def self.landing(ngx15)
        loop {

            return if NyxObjects2::getOrNull(ngx15["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts ""

            puts NGX15::toString(ngx15).green
            puts "uuid: #{ngx15["uuid"]}".yellow
            puts "date: #{Patricia::getObjectReferenceDateTime(ngx15)}".yellow
            puts "location: #{GalaxyFinder::uniqueStringToLocationOrNull(ngx15["ngx15"])}".yellow

            puts ""

            Patricia::mxSourcing(ngx15, mx)

            puts ""

            Patricia::mxTargetting(ngx15, mx)

            puts ""

            mx.item(
                "open".yellow,
                lambda {
                    NGX15::openNGX15(ngx15)
                }
            )

            mx.item("set/update description".yellow, lambda {
                description = Miscellaneous::editTextSynchronously(ngx15["description"] || "").strip
                return if description == ""
                ngx15["description"] = description
                NyxObjects2::put(ngx15)
            })

            mx.item("set/update datetime".yellow, lambda {
                datetime = Miscellaneous::editTextSynchronously(ngx15["referenceDateTime"] || Time.new.utc.iso8601).strip
                ngx15["referenceDateTime"] = datetime
                NyxObjects2::put(ngx15)
            })

            Patricia::mxParentsManagement(ngx15, mx)

            Patricia::mxMoveToNewParent(ngx15, mx)

            mx.item("destroy".yellow, lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy '#{NGX15::toString(ngx15)}': ") then
                    NGX15::ngx15TerminationProtocolReturnBoolean(ngx15)
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # NGX15::ngx15TerminationProtocolReturnBoolean(ngx15)
    def self.ngx15TerminationProtocolReturnBoolean(ngx15)

        puts "Destroying ngx15: #{NGX15::toString(ngx15)}"

        location = GalaxyFinder::uniqueStringToLocationOrNull(ngx15["ngx15"])
        if location then
            puts "Target file '#{location}'"
            puts "Delete as appropriate"
            system("open '#{File.dirname(location)}'")
            LucilleCore::pressEnterToContinue()
        else
            puts "I could not determine the location of #{ngx15["ngx15"]}"
            if !LucilleCore::askQuestionAnswerAsBoolean("Continue with ngx15 deletion ? ") then
                return
            end
        end

        NyxObjects2::destroy(ngx15)

        true
    end
end
