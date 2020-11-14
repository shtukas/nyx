
# encoding: UTF-8

class DataContainers

    # DataContainers::containers()
    def self.containers()
        NyxObjects2::getSet("9644bd94-a917-445a-90b3-5493f5f53ffb")
    end

    # DataContainers::make(name1)
    def self.make(name1)
        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "9644bd94-a917-445a-90b3-5493f5f53ffb",
            "unixtime" => Time.new.to_f,
            "name"     => name1
        }
    end

    # DataContainers::issue(name1)
    def self.issue(name1)
        container = DataContainers::make(name1)
        NyxObjects2::put(container)
        container
    end

    # DataContainers::issueContainerInteractivelyOrNull()
    def self.issueContainerInteractivelyOrNull()
        name1 = LucilleCore::askQuestionAnswerAsString("data container name: ")
        return nil if name1 == ""
        DataContainers::issue(name1)
    end

    # DataContainers::toString(container)
    def self.toString(container)
        "[data container] #{container["name"]}"
    end

    # DataContainers::landing(container)
    def self.landing(container)
        loop {
            system("clear")

            return if NyxObjects2::getOrNull(container["uuid"]).nil?

            puts DataContainers::toString(container).green
            puts "uuid: #{container["uuid"]}".yellow

            mx = LCoreMenuItemsNX1.new()

            sources = Arrows::getSourcesForTarget(container)
            puts "" if !sources.empty?
            sources.each{|source|
                mx.item(
                    "source: #{GenericNyxObject::toString(source)}",
                    lambda { GenericNyxObject::landing(source) }
                )
            }

            targets = Arrows::getTargetsForSource(container)
            targets = GenericNyxObject::applyDateTimeOrderToObjects(targets)
            puts "" if !targets.empty?
            targets
                .each{|object|
                    mx.item(
                        "target: #{GenericNyxObject::toString(object)}",
                        lambda { GenericNyxObject::landing(object) }
                    )
                }

            puts ""
            mx.item("rename".yellow, lambda { 
                name1 = Miscellaneous::editTextSynchronously(container["name"]).strip
                return if name1 == ""
                container["name"] = name1
                NyxObjects2::put(container)
                DataContainers::removeSetDuplicates()
            })
            mx.item("add datapoint".yellow, lambda { 
                datapoint = Datapoints::makeNewDatapointOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(container, datapoint)
            })
            mx.item("add to container".yellow, lambda { 
                l2 = Listings::extractionSelectListingOrMakeListingOrNull()
                return if l2.nil?
                Arrows::issueOrException(l2, container)
            })
            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(container)
                LucilleCore::pressEnterToContinue()
            })
            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy container: '#{DataContainers::toString(container)}': ") then
                    NyxObjects2::destroy(container)
                end
            })
            puts ""
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end
