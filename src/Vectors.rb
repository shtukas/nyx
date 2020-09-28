
# encoding: UTF-8

class Vectors

    # ---------------------------------------------------------------------------
    # Making

    # Vectors::makeVectorFromElements(sequence: Array[String])
    def self.makeVectorFromElements(sequence)

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

    # Vectors::makeVectorsFromString(str: String)
    def self.makeVectorsFromString(str)
        sequence = str.slit("::").map{|element| element.strip }
        Vectors::issueVectorFromElements(sequence)
    end

    # Vectors::issueVectorFromStringOrNothing(str)
    def self.issueVectorFromStringOrNothing(str)
        return nil if !str.start_with?("root")
        vector = Vectors::makeVectorsFromString(str)
        NyxObjects2::put(vector)
        vector
    end

    # Vectors::issueVectorFromStringForTargetOrNull(str, target)
    def self.issueVectorFromStringForTargetOrNull(str, target)
        vector = Vectors::issueVectorFromStringOrNothing(str)
        return if vector.nil?
        Arrows::issueOrException(vector, target)
    end

    # ---------------------------------------------------------------------------
    # Selection

    # Vectors::toString(vector)
    def self.toString(vector)
        "[vector] #{vector["sequence"].join(" :: ")}"
    end

    # Vectors::vectors()
    def self.vectors()
        NyxObjects2::getSet("e54eefdf-53ea-47b0-a70c-c93d958bbe1c")
    end

    # Vectors::selectOneExistingVectorOrNull()
    def self.selectOneExistingVectorOrNull()
        vectors = Vectors::vectors().sort{|v1, v2| v1["sequence"].join(" :: ") <=> v2["sequence"].join(" :: ") }
        LucilleCore::selectEntityFromListOfEntitiesOrNull("vector", vectors, lambda{|o| Vectors::toString(o) })
    end

    # Vectors::selectVectorsByBeginningSequence(sequence)
    def self.selectVectorsByBeginningSequence(sequence)
        pattern = sequence.join(" :: ").downcase
        Vectors::vectors()
            .select{|vector|
                vector["sequence"].join(" :: ").downcase.start_with?(pattern)
            }
    end

    # Vectors::selectDatapointsByBeginningSequence(sequence)
    def self.selectDatapointsByBeginningSequence(sequence)
        Vectors::selectVectorsByBeginningSequence(sequence)
            .map{|vector|
                Arrows::getTargetsForSource(vector)
            }
            .flatten
    end

    # Vectors::selectVectorChildOrNull(vector)
    def self.selectVectorChildOrNull(vector)
        targets = Arrows::getTargetsForSource(vector)
        targets = NyxObjectInterface::applyDateTimeOrderToObjects(targets)
        LucilleCore::selectEntityFromListOfEntitiesOrNull("object", targets, lambda{|o| NyxObjectInterface::toString(o) })
    end

    # ---------------------------------------------------------------------------
    # Ops

    # Vectors::landing(vector)
    def self.landing(vector)
        loop {
            system("clear")

            puts Vectors::toString(vector).green

            puts ""

            mx = LCoreMenuItemsNX1.new()

            targets = Arrows::getTargetsForSource(vector)
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
                Arrows::issueOrException(vector, datapoint)
            })

            mx.item("select existing datapoint + attach to [this]".yellow, lambda {
                datapoint = NSNode1638Extended::selectOneDatapointFromExistingDatapointsOrNull()
                return if datapoint.nil?
                Arrows::issueOrException(vector, datapoint)
            })

            mx.item("detach child".yellow, lambda {
                ns = Vectors::selectVectorChildOrNull(vector)
                return if ns.nil?
                Arrows::unlink(vector, ns)
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

end
