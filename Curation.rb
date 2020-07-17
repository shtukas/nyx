
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

        Cliques::getCliqueNavigationTargets(Cliques::getRootClique())
        .each{|clique|
            system("clear")
            next if KeyValueStore::flagIsTrue(nil, "8f392e54-db01-477a-b923-39c345c66f01:#{clique["uuid"]}")

            puts "Network placement curation"
            puts Cliques::cliqueToString(clique)
            puts ""
            puts "First I am going to show you the clique so that you do a bit of cleaning there"
            LucilleCore::pressEnterToContinue()
            Cliques::landing(clique)
            puts ""
            puts "Now please select a parent for it (possibly the root node)"
            parent = Cliques::selectExistingOrNewCliqueFromRootNavigationOrNull()
            if parent then
                Arrows::make(parent, clique)
            end

            KeyValueStore::setFlagTrue(nil, "8f392e54-db01-477a-b923-39c345c66f01:#{clique["uuid"]}")
            break
        }

        time2 = Time.new.to_f

        Bank::put(curationTimeControlUUID, time2-time1)

    end
end