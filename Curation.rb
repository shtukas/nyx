
# encoding: UTF-8

=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

class Curation

    # Curation::run()
    def self.run()

        curationTimeControlUUID = "56995147-b264-49fb-955c-d5a919395ea3"

        return if (rand*rand) < BankExtended::recoveredDailyTimeInHours(curationTimeControlUUID)

        time1 = Time.new.to_f

        NSDataType3::getNSDataType3NavigationTargets(NSDataType3::getRootNSDataType3())
        .each{|ns3|
            system("clear")
            next if KeyValueStore::flagIsTrue(nil, "8f392e54-db01-477a-b923-39c345c66f01:#{ns3["uuid"]}")

            puts "Network placement curation"
            puts NSDataType3::ns3ToString(ns3)
            puts ""
            puts "First I am going to show you the ns3 so that you do a bit of cleaning there"
            LucilleCore::pressEnterToContinue()
            NSDataType3::landing(ns3)
            puts ""
            puts "Now please select a parent for it (possibly the root node)"
            parent = NSDataType3::selectExistingOrNewNSDataType3FromRootNavigationOrNull()
            if parent then
                Arrows::make(parent, ns3)
            end

            KeyValueStore::setFlagTrue(nil, "8f392e54-db01-477a-b923-39c345c66f01:#{ns3["uuid"]}")
            break
        }

        time2 = Time.new.to_f

        Bank::put(curationTimeControlUUID, time2-time1)

    end
end