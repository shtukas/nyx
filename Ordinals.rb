
# encoding: UTF-8

require 'json'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# ----------------------------------------------------------------------

class Ordinal

    # Ordinal::ordinalToMetric(ordinal)
    def self.ordinalToMetric(ordinal)
        1.5 + Math.exp(-ordinal).to_f/10
    end

    # Ordinal::setOrdinalForToday(uuid, ordinal)
    def self.setOrdinalForToday(uuid, ordinal)

    end
end

class OrdinalsFile
    
    # OrdinalsFile::pathToFile()
    def self.pathToFile()
        "/Users/pascal/Desktop/Catalyst-Ordinals.txt"
    end

    # OrdinalsFile::fileLines()
    def self.fileLines()
    	IO.read(OrdinalsFile::pathToFile())
    		.lines
    		.map{|line| line.strip }
    		.select{|line| line.size>0 }
    end

    # OrdinalsFile::getFileAsStructure()
    def self.getFileAsStructure()
    	OrdinalsFile::fileLines()
			.map{|line|
				spacePosition = line.index(" ")
				{
					"ordinal" => line[0, spacePosition].strip.to_f,
					"description" => line[spacePosition, line.size].strip
				}
			}
    end

    # OrdinalsFile::structureToFileContents(structure)
    def self.structureToFileContents(structure)
    	structure
    		.sort{|i1,i2|
    			i1["ordinal"] <=> i2["ordinal"]
    		}
    		.map{|item| "#{item["ordinal"]} #{item["description"]}" }
    		.join("\n")
    end

    # OrdinalsFile::sendStructureToDisk(structure)
    def self.sendStructureToDisk(structure)
    	folderpath = CommonsUtils::newBinArchivesFolderpath()
    	system("cp '#{OrdinalsFile::pathToFile()}' '#{folderpath}/Catalyst-Ordinals.txt'")
		filecontents = OrdinalsFile::structureToFileContents(structure)
		File.open(OrdinalsFile::pathToFile(), "w"){|f| f.puts(filecontents) }    	
    end

    # OrdinalsFile::doAddRecordsToFile(ordinal, description)
    def self.doAddRecordsToFile(ordinal, description)
    	structure = OrdinalsFile::getFileAsStructure()
    	structure << {
						"ordinal" => ordinal,
						"description" => description
					 }
		OrdinalsFile::sendStructureToDisk(structure)
    end

    # OrdinalsFile::itemToUUID(item)
    def self.itemToUUID(item)
    	Digest::SHA1.hexdigest("#{item["ordinal"]} #{item["description"]}")[0, 8]
    end

    # OrdinalsFile::structureItemToCatalystObject(item)
    def self.structureItemToCatalystObject(item)
		{
			"uuid"               => OrdinalsFile::itemToUUID(item),
			"agent-uid"          => "9bafca47-5084-45e6-bdc3-a53194e6fe62",
			"metric"             => Ordinal::ordinalToMetric(item["ordinal"]),
			"announce"           => "{ordinal: #{"%6.3f" % item["ordinal"]}} #{item["description"]}",
			"commands"           => ["done", "ordinal: <ordinal>"],
			"default-expression" => "done",
			"is-running"         => false,
            "data:description"   => item["description"]
		}  	
    end

    # OrdinalsFile::getCatalystObjects()
    def self.getCatalystObjects()
    	OrdinalsFile::getFileAsStructure()
    		.map{|item| OrdinalsFile::structureItemToCatalystObject(item) }
    end

    # OrdinalsFile::doDone(uuid)
    def self.doDone(uuid)
    	structure = OrdinalsFile::getFileAsStructure()
    		.select{|item| OrdinalsFile::itemToUUID(item)!=uuid }
		OrdinalsFile::sendStructureToDisk(structure)    	
    end

    def OrdinalsFile::setNewOrdinal(objectdescription, ordinal)
    	updatedstructure = OrdinalsFile::getFileAsStructure()
    		.map{|item|
    			if item["description"]==objectdescription then
    				item["ordinal"] = ordinal
    			end
    			item
    		}
    	OrdinalsFile::sendStructureToDisk(updatedstructure)
    end

end


