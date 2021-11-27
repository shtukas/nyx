# encoding: UTF-8

class Nathalie

    # Nathalie::simulationTimeCommitments()
    def self.simulationTimeCommitments()
        {
            "(eva)"  => 3,
            "(work)" => 6,
            "(jedi)" => 2
        }
    end

    # Nathalie::structureStorageKey()
    def self.structureStorageKey()
        Digest::SHA1.hexdigest("aa3d441d-a247-489d-9662-7ee3f668adcf:#{IO.read(__FILE__)}")
    end

    # Nathalie::computeNewStructure()
    def self.computeNewStructure()
        zero = {
            "Monitor"  => [],
            "overflow" => [],
            "Dated"    => [],
            "Tail"     => []
        }

        Domain::domains()
            .sort{|d1, d2| d1 <=> d2 } # for the moment we apply a dummy ordering
            .zip([8, 5, 2]) # 8 elements of the domain with the lowest completion ratio, etc...
            .map{|pair|
                domain, cardinal = pair
                structure = Nx50s::structureForDomain(domain)
                structure["Dated"] = structure["Dated"].take(cardinal)
                structure["Tail"]  = structure["Tail"].take([0, structure["Dated"].size - cardinal].max)
                structure
            }
            .reduce(zero){|cursor, struc|
                cursor["Monitor"] = cursor["Monitor"] + struc["Monitor"]
                cursor["Dated"]   = (cursor["Dated"] + struc["Dated"]).shuffle
                cursor["Tail"]    = (cursor["Tail"] + struc["Tail"]).shuffle
                cursor
            }
    end

    # Nathalie::structure()
    def self.structure()
        structure = KeyValueStore::getOrNull(nil, Nathalie::structureStorageKey())
        if structure.nil? then
            structure = Nathalie::computeNewStructure()
            KeyValueStore::set(nil, Nathalie::structureStorageKey(), JSON.generate(structure))
        else
            structure = JSON.parse(structure)
        end
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nathalie] removing uuid: #{uuid}"
            structure["Dated"] = structure["Dated"].select{|ns16| ns16["uuid"] != uuid }
            structure["Tail"]  = structure["Tail"].select{|ns16| ns16["uuid"] != uuid }
            KeyValueStore::set(nil, Nathalie::structureStorageKey(), JSON.pretty_generate(structure))
        end
        structure
    end
end
