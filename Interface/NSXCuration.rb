# encoding: UTF-8

# This variable contains the objects of the current display.
# We use it to speed up display after some operations

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/CatalystStandardTargets.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/DataPoints.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Catalyst/Starlight.rb"

# ------------------------------------------------------------------------

class NSXCuration
    # NSXCuration::curation()
    def self.curation()
        system("clear")
        puts "#Curation"
        DataPoints::datapoints()
            .map{|datapoint| datapoint["tags"] }
            .flatten
            .uniq
            .sort
            .each{|tag|
                next if KeyValueStore::flagIsTrue(nil, "8a17aa35-9789-455c-97a9-59c1337fb00f:#{tag}")
                if LucilleCore::askQuestionAnswerAsBoolean("Make tag '#{tag}' ( #{DataPoints::getDataPointsByTag(tag).size} ) into Starlight node ? ", false) then
                    datapoints = DataPoints::getDataPointsByTag(tag)
                    node = {
                        "uuid" => SecureRandom.uuid,
                        "creationTimestamp" => Time.new.to_f,
                        "name" => tag
                    }
                    puts node
                    StartlightNodes::save(node)
                    datapoints.each{|datapoint|
                        puts datapoint
                        StarlightDataClaims::makeClaimGivenNodeAndDataPoint(node, datapoint)
                    }
                    KeyValueStore::setFlagTrue(nil, "8a17aa35-9789-455c-97a9-59c1337fb00f:#{tag}")
                    return
                end
                KeyValueStore::setFlagTrue(nil, "8a17aa35-9789-455c-97a9-59c1337fb00f:#{tag}")
            }
    end
end


