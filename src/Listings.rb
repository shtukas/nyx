
# encoding: UTF-8

class Listings

    # Listings::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "abb20581-f020-43e1-9c37-6c3ef343d2f5",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # Listings::issue(name1)
    def self.issue(name1)
        listing = Listings::make(name1)
        NyxObjects2::put(listing)
        listing
    end

    # Listings::issueSetInteractivelyOrNull()
    def self.issueSetInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("listing name: ")
        return nil if name1 == ""
        Listings::issue(name1)
    end

    # Listings::listings()
    def self.listings()
        NyxObjects2::getSet("287041db-39ac-464c-b557-2f172e721111")
    end

    # Listings::toString(listing)
    def self.toString(listing)
        "[listing] #{listing["name"]}"
    end

    # Listings::landing(listing)
    def self.landing(listing)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(listing["uuid"]).nil?

            puts Listings::toString(listing).green
            puts "uuid: #{listing["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(listing)
            targets = targets.select{|target| !NyxObjectInterface::isTag(target) }
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
            targets
                .each{|object|
                    mx.item(
                        NyxObjectInterface::toString(object),
                        lambda { NyxObjectInterface::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(listing["name"]).strip
                return if name1 == ""
                listing["name"] = name1
                NyxObjects2::put(listing)
                Listings::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = NGX15::issueNewNGX15InteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(listing, datapoint)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(listing)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy listing".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy listing: '#{Listings::toString(listing)}': ") then
                    NyxObjects2::destroy(listing)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
