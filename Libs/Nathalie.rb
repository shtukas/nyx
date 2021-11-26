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

    # Nathalie::orderedNS16sForDomain(domain)
    def self.orderedNS16sForDomain(domain)
        structure = Nx50s::structure(domain)
        NS16sOperator::ns16s(domain, structure)
    end

    # Nathalie::newCollectionNS16s()
    def self.newCollectionNS16s()
        Domain::domains()
            .map{|domain| 
                Nathalie::orderedNS16sForDomain(domain)
                    .first(5)
                    .map{|ns16|
                        ns16["x-domain"] = domain
                        ns16
                    } 
            }
            .flatten
            .shuffle
    end

    # Nathalie::collectionStorageKey()
    def self.collectionStorageKey()
        Digest::SHA1.hexdigest("aa3d441d-a247-489d-9662-7ee3f668adcf:#{IO.read(__FILE__)}")
    end

    # Nathalie::issueNewCollection()
    def self.issueNewCollection()
        collection = {
            "unixtime" => Time.new.to_i,
            "ns16s"    => Nathalie::newCollectionNS16s()
        }
        KeyValueStore::set(nil, Nathalie::collectionStorageKey(), JSON.pretty_generate(collection))
        collection
    end

    # Nathalie::getNS16sFromCollection()
    def self.getNS16sFromCollection()
        collection = KeyValueStore::getOrNull(nil, Nathalie::collectionStorageKey())
        if collection.nil? then
            collection = Nathalie::issueNewCollection()
        else
            collection = JSON.parse(collection)
        end
        ns16s = collection["ns16s"]
        while uuid = Mercury::dequeueFirstValueOrNull("A4EC3B4B-NATHALIE-COLLECTION-REMOVE") do
            puts "[Nathalie] removing uuid: #{uuid}"
            ns16s = ns16s.select{|ns16| ns16["uuid"] != uuid }
        end
        ns16s
    end
end
