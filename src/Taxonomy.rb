
# encoding: UTF-8

class Taxonomy

    # ---------------------------------------------------------------------------
    # Making

    # Taxonomy::makeTaxonomyItemFromElements(sequence: Array[String])
    def self.makeTaxonomyItemFromElements(sequence)

        # We need to ensure that the first element is always "root"
        if sequence.empty? or sequence[0] != "root" then
            puts "sequence: #{JSON.generate(sequence)}"
            raise "[error: 1a34a60e-f014-4c17-9a75-a64fd162ec7a]"
        end

        {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "e54eefdf-53ea-47b0-a70c-c93d958bbe1c",
            "unixtime" => Time.new.to_f,
            "sequence" => sequence
        }
    end

    # Taxonomy::makeTaxonomyItemFromString(str: String)
    def self.makeTaxonomyItemFromString(str)
        sequence = str.slit("::").map{|element| element.strip }
        Taxonomy::issueTaxonomyItemFromElements(sequence)
    end

    # Taxonomy::issueTaxonomyItemFromStringOrNothing(str)
    def self.issueTaxonomyItemFromStringOrNothing(str)
        return nil if !str.start_with?("root")
        item = Taxonomy::makeTaxonomyItemFromString(str)
        NyxObjects2::put(item)
        item
    end

    # Taxonomy::issueTaxonomyItemFromStringForTargetOrNull(str, target)
    def self.issueTaxonomyItemFromStringForTargetOrNull(str, target)
        item = Taxonomy::issueTaxonomyItemFromStringOrNothing(str)
        return if item.nil?
        Arrows::issueOrException(item, target)
    end

    # ---------------------------------------------------------------------------
    # Selection

    # Taxonomy::toString(item)
    def self.toString(item)
        "[taxonomy item] #{item["sequence"].join(" :: ")}"
    end

    # Taxonomy::items()
    def self.items()
        NyxObjects2::getSet("e54eefdf-53ea-47b0-a70c-c93d958bbe1c")
    end

    # Taxonomy::selectOneExistingTaxonomyItemOrNull()
    def self.selectOneExistingTaxonomyItemOrNull()
        items = Taxonomy::items().sort{|v1, v2| v1["sequence"].join(" :: ") <=> v2["sequence"].join(" :: ") }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("item", items, lambda{|o| Taxonomy::toString(o) })
    end

    # Taxonomy::selectTaxonomyItemByBeginningSequence(sequence)
    def self.selectTaxonomyItemByBeginningSequence(sequence)
        pattern = sequence.join(" :: ").downcase
        Taxonomy::items()
            .select{|item|
                item["sequence"].join(" :: ").downcase.start_with?(pattern)
            }
    end

    # Taxonomy::selectDatapointsByTaxonomyItemBeginningSequence(sequence)
    def self.selectDatapointsByTaxonomyItemBeginningSequence(sequence)
        Taxonomy::selectTaxonomyItemByBeginningSequence(sequence)
            .map{|item|
                Arrows::getTargetsForSource(item)
            }
            .flatten
    end

    # Taxonomy::selectOneTaxonomyItemChildOrNull(item)
    def self.selectOneTaxonomyItemChildOrNull(item)
        targets = Arrows::getTargetsForSource(item)
        targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| NyxObjectInterface::toString(o) })
    end

    # ---------------------------------------------------------------------------
    # Ops

    # Taxonomy::landing(item)
    def self.landing(item)
        loop {
            system("clear")

            puts Taxonomy::toString(item).green

            puts ""

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(item)
            targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
            targets
                .each{|object|
                    mx.item(
                        NyxObjectInterface::toString(object),
                        lambda { NyxObjectInterface::landing(object) }
                    )
                }

            puts ""

            mx.item("make new datapoint + attach to [this]".yellow, lambda {
                datapoint = NSNode1638::issueNewPointInteractivelyOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(item, datapoint)
            })

            mx.item("select existing datapoint + attach to [this]".yellow, lambda {
                datapoint = NSNode1638Extended::selectOneDatapointFromExistingDatapointsOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(item, datapoint)
            })

            mx.item("detach child".yellow, lambda {
                ns = Taxonomy::selectOneTaxonomyItemChildOrNull(item)
                return if ns.nil?
                Arrows::unlink(item, ns)
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

end
