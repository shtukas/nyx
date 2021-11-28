# encoding: UTF-8

class Nathalie

    # Nathalie::expectation(domain)
    def self.expectation(domain)
        map = {
            "(eva)"           => 3,
            "(work)"          => 6,
            "(jedi)"          => 2,
            "(entertainment)" => 1
        }
        map[domain]
    end

    # Nathalie::dataStorageKey()
    def self.dataStorageKey()
        Digest::SHA1.hexdigest("aa3d441d-a247-489d-9662-7ee3f668adff:#{Utils::today()}:#{IO.read(__FILE__)}")
    end

    # Nathalie::domains()
    def self.domains()
        # This is a slightly different list than (subset of) Domain::domains()
        # Because there are days we do not want (work), for instance
        return ["(eva)", "(jedi)", "(entertainment)"] if Time.new.wday == 6
        return ["(eva)", "(jedi)", "(entertainment)"] if Time.new.wday == 0
        Domain::domains()
    end

    # Nathalie::listingDomains()
    def self.listingDomains()
        Nathalie::domains()
            .map {|domain|
                {
                    "domain" => domain,
                    "ratio"  => BankExtended::stdRecoveredDailyTimeInHours(Domain::domainToBankAccount(domain)).to_f/Nathalie::expectation(domain)
                }
            }
            .sort{|p1, p2|
                p1["ratio"] <=> p2["ratio"]
            }
            .first(2)
            .map{|packet| packet["domain"] }
    end

    # Nathalie::computeNewNx77()
    def self.computeNewNx77()
        puts "Nathalie::computeNewNx77()"
        monitor    = Nathalie::listingDomains().map{|domain| Nx50s::structureForDomain(domain)["Monitor"] }.flatten
        ns16sPart1 = Nathalie::listingDomains().map{|domain| DisplayListingParameters::ns16sPart1(domain) }.flatten.first(5)
        ns16sPart1 = DisplayListingParameters::removeDuplicates(ns16sPart1)
        dated      = Nathalie::listingDomains().map{|domain| Nx50s::structureForDomain(domain)["Dated"].first(2) }.flatten
        tail       = Nathalie::listingDomains().map{|domain| Nx50s::structureForDomain(domain)["Tail"].first(2) }.flatten
        listingParameters = {
            "domain"   => nil,
            "Monitor"  => monitor,
            "overflow" => [],
            "ns16s"    => (ns16sPart1 + dated + tail).shuffle
        }
        {
            "unixtime"   => Time.new.to_i,
            "parameters" => listingParameters
        }
    end

    # Nathalie::listingParameters()
    def self.listingParameters()
        nx77 = KeyValueStore::getOrNull(nil, Nathalie::dataStorageKey())
        if nx77.nil? then
            nx77 = Nathalie::computeNewNx77()
        else
            nx77 = JSON.parse(nx77)
        end
        if (Time.new.to_f - nx77["unixtime"]) > 36400*4 then # We expire after 4 hours
            nx77 = Nathalie::computeNewNx77()
        end
        if nx77["parameters"]["ns16s"].empty? then
            nx77 = Nathalie::computeNewNx77()
        end
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nathalie] removing uuid: #{uuid}"
            nx77["parameters"]["ns16s"]  = nx77["parameters"]["ns16s"].select{|ns16| ns16["uuid"] != uuid }
        end
        KeyValueStore::set(nil, Nathalie::dataStorageKey(), JSON.generate(nx77))
        nx77["parameters"]
    end


    # Nathalie::dx()
    def self.dx()
        domainToString = lambda{|domain|
            domain.gsub("(", "").gsub(")", "")
        }
        Nathalie::domains()
            .map{|domain|
                account = Domain::domainToBankAccount(domain)
                {
                    "domain" => domain,
                    "rt"     => BankExtended::stdRecoveredDailyTimeInHours(account),
                    "today"  => Bank::valueAtDate(account, Utils::today()).to_f/3600,
                    "ratio"  => BankExtended::stdRecoveredDailyTimeInHours(Domain::domainToBankAccount(domain)).to_f/Nathalie::expectation(domain)
                }
            }
            .sort{|p1, p2| p1["ratio"]<=>p2["ratio"] }
            .map{|px|
                "(#{domainToString.call(px["domain"])}: #{(100*px["ratio"]).to_i}% of #{Nathalie::expectation(px["domain"])} hours)"
            }
            .join(" ")
    end
end
