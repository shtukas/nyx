# encoding: UTF-8

$NathalieData = nil

class Nathalie

    # Nathalie::simulationTimeCommitments()
    def self.simulationTimeCommitments()
        {
            "(eva)"  => 3,
            "(work)" => 6,
            "(jedi)" => 2
        }
    end

    # Nathalie::dataStorageKey()
    def self.dataStorageKey()
        Digest::SHA1.hexdigest("aa3d441d-a247-489d-9662-7ee3f668adcf:#{IO.read(__FILE__)}")
    end

    # Nathalie::computeNewListingParameters()
    def self.computeNewListingParameters()
        puts "Nathalie::computeNewListingParameters()"
        monitor    = Domain::domains().map{|domain| Nx50s::structureForDomain(domain)["Monitor"] }.flatten
        ns16sPart1 = Domain::domains().map{|domain| DisplayListingParameters::ns16sPart1(domain) }.flatten.first(5)
        ns16sPart1 = DisplayListingParameters::removeDuplicates(ns16sPart1)
        dated      = Domain::domains().map{|domain| Nx50s::structureForDomain(domain)["Dated"].first(2) }.flatten
        tail       = Domain::domains().map{|domain| Nx50s::structureForDomain(domain)["Tail"].first(2) }.flatten

        {
            "domain"   => nil,
            "Monitor"  => monitor,
            "overflow" => [],
            "ns16s"    => ns16sPart1 + dated + tail
        }
    end

    # Nathalie::listingParameters()
    def self.listingParameters()
        if $NathalieData.nil? then
            $NathalieData = Nathalie::computeNewListingParameters()
        end
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nathalie] removing uuid: #{uuid}"
            $NathalieData["ns16s"]  = $NathalieData["ns16s"].select{|ns16| ns16["uuid"] != uuid }
        end
        $NathalieData.clone
    end
end
