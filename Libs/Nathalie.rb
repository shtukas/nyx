# encoding: UTF-8

$NathalieData = nil

class Nathalie

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
        map1 = {
            "(eva)"  => 3,
            "(work)" => 6,
            "(jedi)" => 2,
            "(entertainment)" => 1
        }
        Nathalie::domains()
            .map {|domain|
                {
                    "domain" => domain,
                    "ratio"  => BankExtended::stdRecoveredDailyTimeInHours(Domain::domainToBankAccount(domain)).to_f/map1[domain]
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
        if $NathalieData.nil? then
            $NathalieData = Nathalie::computeNewListingParameters()
        end
        if $NathalieData["ns16s"].empty? then
            $NathalieData = Nathalie::computeNewListingParameters()
        end
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nathalie] removing uuid: #{uuid}"
            $NathalieData["ns16s"]  = $NathalieData["ns16s"].select{|ns16| ns16["uuid"] != uuid }
        end
        $NathalieData.clone
    end
end
