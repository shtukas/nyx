
# encoding: UTF-8

require 'json'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# ----------------------------------------------------------------------

class Ordinals
    
    # Ordinals::pathToFile()
    def self.pathToFile()
        "/Users/pascal/Desktop/Catalyst-Ordinals.txt"
    end

    # Ordinals::fileLines()
    def self.fileLines()
    	IO.read(Ordinals::pathToFile())
    		.lines
    		.map{|line| line.strip }
    		.select{|line| line.size>0 }
    end

    # Ordinals::getFileAsStructure()
    def self.getFileAsStructure()
    	Ordinals::fileLines()
			.map{|line|
				spacePosition = line.index(" ")
				{
					"ordinal" => line[0, spacePosition].strip.to_f,
					"description" => line[spacePosition, line.size].strip
				}
			}
    end

    # Ordinals::structureToFileContents(structure)
    def self.structureToFileContents(structure)
    	structure
    		.sort{|i1,i2|
    			i1["ordinal"] <=> i2["ordinal"]
    		}
    		.map{|item| "#{item["ordinal"]} #{item["description"]}" }
    		.join("\n")
    end

    # Ordinals::sendStructureToDisk(structure)
    def self.sendStructureToDisk(structure)
    	folderpath = CommonsUtils::newBinArchivesFolderpath()
    	system("cp '#{Ordinals::pathToFile()}' '#{folderpath}/Catalyst-Ordinals.txt'")
		filecontents = Ordinals::structureToFileContents(structure)
		File.open(Ordinals::pathToFile(), "w"){|f| f.puts(filecontents) }    	
    end

    # Ordinals::doAddRecordsToFile(ordinal, description)
    def self.doAddRecordsToFile(ordinal, description)
    	structure = Ordinals::getFileAsStructure()
    	structure << {
						"ordinal" => ordinal,
						"description" => description
					 }
		Ordinals::sendStructureToDisk(structure)
    end

    # Ordinals::itemToUUID(item)
    def self.itemToUUID(item)
    	Digest::SHA1.hexdigest("#{item["ordinal"]} #{item["description"]}")[0, 8]
    end

    # Ordinals::structureItemToCatalystObject(item)
    def self.structureItemToCatalystObject(item)
		{
			"uuid"               => Ordinals::itemToUUID(item),
			"agent-uid"          => "9bafca47-5084-45e6-bdc3-a53194e6fe62",
			"metric"             => 1.5 + Math.exp(-item["ordinal"]).to_f/10,
			"announce"           => "[#{"%6.3f" % item["ordinal"]}] #{item["description"]}",
			"commands"           => ["done", "ordinal:"],
			"default-expression" => "done",
			"is-running"         => false
		}  	
    end

    # Ordinals::getCatalystObjects()
    def self.getCatalystObjects()
    	Ordinals::getFileAsStructure()
    		.map{|item| Ordinals::structureItemToCatalystObject(item) }
    end

    # Ordinals::doDone(uuid)
    def self.doDone(uuid)
    	structure = Ordinals::getFileAsStructure()
    		.select{|item| Ordinals::itemToUUID(item)!=uuid }
		Ordinals::sendStructureToDisk(structure)    	
    end

    def Ordinals::setNewOrdinal(objectuuid, ordinal)
    	updatedstructure = Ordinals::getFileAsStructure()
    		.map{|item|
    			if Ordinals::itemToUUID(item)==objectuuid then
    				item["ordinal"] = ordinal
    			end
    			item
    		}
    	Ordinals::sendStructureToDisk(updatedstructure)
    end

end


