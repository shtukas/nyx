
# encoding: UTF-8

class OrdinalPoints

    # OrdinalPoints::repositoryPath()
    def self.repositoryPath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Ordinal-Points"
    end

    # OrdinalPoints::issueTextPointInteractivelyOrNull(ordinal)
    def self.issueTextPointInteractivelyOrNull(ordinal)
        text = Miscellaneous::editTextSynchronously("")
        storageKey = SecureRandom.hex
        KeyValueStore::set(nil, storageKey, text)
        uuid = Miscellaneous::l22()
        object = {
          "uuid"       => uuid,
          "type"       => "text",
          "storageKey" => storageKey,
          "ordinal"    => ordinal
        }
        filepath = "#{OrdinalPoints::repositoryPath()}/#{uuid}.json"
        File.open(filepath, "w"){|f| f.puts(JSON.pretty_generate(object)) }
        object
    end

    # OrdinalPoints::getOrdinalPointByUuid(uuid)
    def self.getOrdinalPointByUuid(uuid)
        filepath = "#{OrdinalPoints::repositoryPath()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        JSON.parse(IO.read(filepath))
    end

    # OrdinalPoints::destroyPointUuid(uuid)
    def self.destroyPointUuid(uuid)
        filepath = "#{OrdinalPoints::repositoryPath()}/#{uuid}.json"
        return nil if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # OrdinalPoints::repositoryUuids()
    def self.repositoryUuids()
        Dir.entries(OrdinalPoints::repositoryPath())
            .select{|filepath|
                filepath[-5, 5] == ".json"
            }
            .map{|filepath|
                filepath[0, filepath.size-5]
            }
    end

    # OrdinalPoints::ordinalPoints()
    def self.ordinalPoints()
        OrdinalPoints::repositoryUuids()
            .map{|uuid| OrdinalPoints::getOrdinalPointByUuid(uuid) }
    end

    # OrdinalPoints::ordinalToMetric(ordinal)
    def self.ordinalToMetric(ordinal)
        # 0.69  -> 0.66 
        0.66 + 0.03 * Math.exp(-ordinal) # We should probably keep the ordinals positive
    end

    # OrdinalPoints::toString(point)
    def self.toString(point)
        ordinal = point["ordinal"]
        text = KeyValueStore::getOrNull(nil, point["storageKey"]) 
        return "[ordinal point] (#{ordinal}) -> no body found" if text.nil?
        return "[ordinal point] (#{ordinal}) -> empty body" if text == ""
        "[ordinal point] (ordinal: #{ordinal}) #{text.lines.first.strip}"
    end

    # OrdinalPoints::ordinalPointToCatalystObject(point)
    def self.ordinalPointToCatalystObject(point)
        uuid = point["uuid"]
        ordinal = point["ordinal"]
        {
            "uuid"             => uuid,
            "body"             => OrdinalPoints::toString(point).green,
            "metric"           => OrdinalPoints::ordinalToMetric(ordinal),
            "landing"          => lambda {},
            "nextNaturalStep"  => lambda {},
            "done"             => lambda {
                if LucilleCore::askQuestionAnswerAsBoolean("confirm '#{OrdinalPoints::toString(point)}' done ? ") then
                    OrdinalPoints::destroyPointUuid(uuid)
                end
            },
            "isRunning"        => false,
            "isRunningForLong" => false,
            "x-ordinal-point"  => true
        }
    end

    # OrdinalPoints::getCatalystObjects()
    def self.getCatalystObjects()
        OrdinalPoints::ordinalPoints()
            .map{|object| OrdinalPoints::ordinalPointToCatalystObject(object) }
    end
end
