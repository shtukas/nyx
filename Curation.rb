
# encoding: UTF-8

=begin
    KeyToStringOnDiskStore::setFlagTrue(repositorylocation or nil, key)
    KeyToStringOnDiskStore::setFlagFalse(repositorylocation or nil, key)
    KeyToStringOnDiskStore::flagIsTrue(repositorylocation or nil, key)

    KeyToStringOnDiskStore::set(repositorylocation or nil, key, value)
    KeyToStringOnDiskStore::getOrNull(repositorylocation or nil, key)
    KeyToStringOnDiskStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyToStringOnDiskStore::destroy(repositorylocation or nil, key)
=end

class Curation

    # Curation::run()
    def self.run()

        curationTimeControlUUID = "56995147-b264-49fb-955c-d5a919395ea3"
        return if (rand*rand) < BankExtended::recoveredDailyTimeInHours(curationTimeControlUUID)
        time1 = Time.new.to_f

        NSDataType2::ns2s().each{|ns2|
            next if !DescriptionZ::getLastDescriptionForSourceOrNull(ns2).nil?
            next if NavigationPoint::getDownstreamNavigationPointsType1(ns2).size <= 1
            system("clear")
            puts "n2 needs description"
            sleep 2
            NSDataType2::landing(ns2)
            return
        }

        time2 = Time.new.to_f
        Bank::put(curationTimeControlUUID, time2-time1)

    end
end