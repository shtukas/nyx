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
        Digest::SHA1.hexdigest("aa3d441d-a247-489d-9662-7ee3f668adcf:#{IO.read(__FILE__)}")
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

    # Nathalie::computeNewListingParameters()
    def self.computeNewListingParameters()
        puts "Nathalie::computeNewListingParameters()"
        monitor    = Nathalie::listingDomains().map{|domain| Nx50s::structureForDomain(domain)["Monitor"] }.flatten
        ns16sPart1 = Nathalie::listingDomains().map{|domain| DisplayListingParameters::ns16sPart1(domain) }.flatten.first(5)
        ns16sPart1 = DisplayListingParameters::removeDuplicates(ns16sPart1)
        dated      = Nathalie::listingDomains().map{|domain| Nx50s::structureForDomain(domain)["Dated"].first(2) }.flatten
        tail       = Nathalie::listingDomains().map{|domain| Nx50s::structureForDomain(domain)["Tail"].first(2) }.flatten
        {
            "domain"   => nil,
            "Monitor"  => monitor,
            "overflow" => [],
            "ns16s"    => (ns16sPart1 + dated + tail).shuffle
        }
    end

    # Nathalie::listingParameters()
    def self.listingParameters()
        nathalie = KeyValueStore::getOrNull(nil, "E393A7D1-7601-4DE1-BA18-775D5E75C431")
        if nathalie.nil? then
            nathalie = Nathalie::computeNewListingParameters()
        else
            nathalie = JSON.parse(nathalie)
        end
        if nathalie["ns16s"].empty? then
            nathalie = Nathalie::computeNewListingParameters()
        end
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nathalie] removing uuid: #{uuid}"
            nathalie["ns16s"]  = nathalie["ns16s"].select{|ns16| ns16["uuid"] != uuid }
        end
        KeyValueStore::set(nil, "E393A7D1-7601-4DE1-BA18-775D5E75C431", JSON.generate(nathalie))
        nathalie
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
