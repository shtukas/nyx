
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

class Counter0731
    def initialize()
        @count = 0
    end
    def increment()
        @count = @count + 1
    end
    def hasReached(n)
        @count >= n
    end
end

class Curation

    # Curation::oneCurationStep()
    def self.oneCurationStep()

        counter = Counter0731.new()

        # Give a description to the aion-point cubes which do not have one

        NSDataType1::cubes()
        .each{|cube|

            return if counter.hasReached(10)

            next if NSDataType1::getAsteroidsForCube(cube).size > 0
            next if DescriptionZ::getLastDescriptionForSourceOrNull(cube)
            ns0 = NSDataType1::cubeToLastFrameOrNull(cube)
            next if ns0.nil?
            next if ns0["type"] != "aion-point"

            system("clear")

            NSDataType0s::openFrame(cube, ns0)

            counter.increment()

            description = LucilleCore::askQuestionAnswerAsString("description (or type 'dive'): ")
            next if description == ""
            if description == "dive" then
                NSDataType1::landing(cube)
                next
            end
            descriptionz = DescriptionZ::issue(description)
            Arrows::issueOrException(cube, descriptionz)
        }

        # Give a description to concepts which do not have one

        NSDataType2::concepts()
        .each{|concept|
            return if counter.hasReached(10)
            next if DescriptionZ::getLastDescriptionForSourceOrNull(concept)
            NSDataType2::landing(concept)
            counter.increment()
        }

        # Give a upstream concepts to cubes which do not have one

        NSDataType1::cubes()
        .each{|cube|
            return if counter.hasReached(10)
            next if Type1Type2CommonInterface::getUpstreamPages(cube).size > 0
            NSDataType2::landing(cube)
            counter.increment()
        }
    end

    # Curation::catalystTodoListingCurationOpportunity()
    def self.catalystTodoListingCurationOpportunity()
        return if rand < BankExtended::recoveredDailyTimeInHours("56995147-b264-49fb-955c-d5a919395ea3")
        return if !LucilleCore::askQuestionAnswerAsBoolean("spare some time for curation ? ", true)
        time1 = Time.new.to_f

        Curation::oneCurationStep()

        time2 = Time.new.to_f
        Bank::put("56995147-b264-49fb-955c-d5a919395ea3", time2-time1)
    end

    # Curation::session()
    def self.session()
        time1 = Time.new.to_f
        loop {
            Curation::oneCurationStep()
            break if ((Time.new.to_i-time1) > 1200)
        }
    end

end