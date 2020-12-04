# encoding: UTF-8

class Curation

    # Curation::getCurationLambdaOrNull()
    def self.getCurationLambdaOrNull()
        objectShouldHaveAnAsteroidParent = lambda {|x2|
            [
                "smbc-comics.com", 
                "thekidshouldseethis.com", 
                "xkcd.com",
                "apod.nasa.gov",
                "dilbert.com",
                "geekculture.com",
                "schneier.com",
                "ribbonfarm.com",
                "terrytao.wordpress.com"
            ].any?{|fragment| Patricia::toString(x2).include?(fragment) }
        }

        objects = Quarks::quarks()
                    .select{|x| Arrows::getSourcesForTarget(x).none?{|x2| Patricia::isAsteroid(x2) } }
                    .select{|x| !NavigationNodes::objectDescentFromNavigationRoot(x) }

        return nil if objects.size == 0

        object = objects.first
        if objectShouldHaveAnAsteroidParent.call(object) then
            Asteroids::issueAsteroidBurnerFromTarget(object)
            return Curation::getCurationLambdaOrNull()
        end

        lambda { Patricia::landing(object) }
    end

    # Curation::runOnce()
    def self.runOnce()
        startTime = Time.new.to_f
        l = Curation::getCurationLambdaOrNull()
        return if l.nil?
        l.call()
        timespan = Time.new.to_f - startTime

        puts "#{timespan} at curation-12774764-77df-4185-ae4c-85bb176484ca"
        Bank::put("curation-12774764-77df-4185-ae4c-85bb176484ca", timespan)

        puts "#{timespan} at ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0"
        Bank::put("ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0", timespan)
    end

    # Curation::catalystObjects()
    def self.catalystObjects()
        return [] if Curation::getCurationLambdaOrNull().nil?
        metric = ExecutionContexts::metric2("ExecutionContext-62CA63E8-190D-4C05-AA0F-027A999003C0", 2, "curation-12774764-77df-4185-ae4c-85bb176484ca")
        {
            "uuid"             => "e113b812-d495-4735-b831-16ac69ef5d92",
            "body"             => "nyx curation",
            "metric"           => metric,
            "landing"          => lambda {
                puts "Curation doesn't have a landing per se"
                LucilleCore::pressEnterToContinue()
            },
            "nextNaturalStep"  => lambda { Curation::runOnce() }
        }
    end
end


