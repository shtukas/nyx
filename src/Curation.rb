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

    # Curation::run()
    def self.run()
        loop {
            loopStartTime = Time.new.to_f
            l = Curation::getCurationLambdaOrNull()
            break if l.nil?
            l.call()
            Bank::put("e8ee808e-1175-425f-87cc-3a5824baccd5", Time.new.to_f - loopStartTime)
            break if !LucilleCore::askQuestionAnswerAsBoolean("continue ? : ", true)
        }
        
    end

    # Curation::catalystObjects()
    def self.catalystObjects()
        return [] if Curation::getCurationLambdaOrNull().nil?
        return [] if BankExtended::recoveredDailyTimeInHours("e8ee808e-1175-425f-87cc-3a5824baccd5") > 0.5
        {
            "uuid"             => "e113b812-d495-4735-b831-16ac69ef5d92",
            "body"             => "nyx curation",
            "metric"           => SingleExecutionContext::metric("e8ee808e-1175-425f-87cc-3a5824baccd5"),
            "landing"          => lambda {
                puts "Curation doesn't have a landing per se"
                LucilleCore::pressEnterToContinue()
            },
            "nextNaturalStep"  => lambda { Curation::run() }
        }
    end
end


