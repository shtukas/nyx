
# encoding: UTF-8

require 'json'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# ----------------------------------------------------------------------

class Ordinal

    # NSXOrdinal::ordinalToMetric(ordinal)
    def self.ordinalToMetric(ordinal)
        1.5 + Math.exp(-ordinal).to_f/10
    end

    # NSXOrdinal::setOrdinalForToday(uuid, ordinal)
    def self.setOrdinalForToday(uuid, ordinal)

    end
end

class NSXOrdinalsFile
    
    # NSXOrdinalsFile::pathToFile()
    def self.pathToFile()
        "/Users/pascal/Desktop/Catalyst-Ordinals.txt"
    end

    # NSXOrdinalsFile::fileLines()
    def self.fileLines()
    	IO.read(NSXOrdinalsFile::pathToFile())
    		.lines
    		.map{|line| line.strip }
    		.select{|line| line.size>0 }
    end

    # NSXOrdinalsFile::getFileAsStructure()
    def self.getFileAsStructure()
    	NSXOrdinalsFile::fileLines()
			.map{|line|
				spacePosition = line.index(" ")
				{
					"ordinal" => line[0, spacePosition].strip.to_f,
					"description" => line[spacePosition, line.size].strip
				}
			}
    end

    # NSXOrdinalsFile::structureToFileContents(structure)
    def self.structureToFileContents(structure)
    	structure
    		.sort{|i1,i2|
    			i1["ordinal"] <=> i2["ordinal"]
    		}
    		.map{|item| "#{item["ordinal"]} #{item["description"]}" }
    		.join("\n")
    end

    # NSXOrdinalsFile::sendStructureToDisk(structure)
    def self.sendStructureToDisk(structure)
    	folderpath = NSXMiscUtils::newBinArchivesFolderpath()
    	system("cp '#{NSXOrdinalsFile::pathToFile()}' '#{folderpath}/Catalyst-Ordinals.txt'")
		filecontents = NSXOrdinalsFile::structureToFileContents(structure)
		File.open(NSXOrdinalsFile::pathToFile(), "w"){|f| f.puts(filecontents) }    	
    end

    # NSXOrdinalsFile::doAddRecordsToFile(ordinal, description)
    def self.doAddRecordsToFile(ordinal, description)
    	structure = NSXOrdinalsFile::getFileAsStructure()
    	structure << {
						"ordinal" => ordinal,
						"description" => description
					 }
		NSXOrdinalsFile::sendStructureToDisk(structure)
    end

    # NSXOrdinalsFile::itemToUUID(item)
    def self.itemToUUID(item)
    	Digest::SHA1.hexdigest("#{item["ordinal"]} #{item["description"]}")[0, 8]
    end

    # NSXOrdinalsFile::structureItemToCatalystObject(item)
    def self.structureItemToCatalystObject(item)
		{
			"uuid"               => NSXOrdinalsFile::itemToUUID(item),
			"agent-uid"          => "9bafca47-5084-45e6-bdc3-a53194e6fe62",
			"metric"             => NSXOrdinal::ordinalToMetric(item["ordinal"]),
			"announce"           => "{ordinal: #{"%6.3f" % item["ordinal"]}} #{item["description"]}",
			"commands"           => ["done", "ordinal: <ordinal>"],
			"default-expression" => "done",
			"is-running"         => false,
            "data:description"   => item["description"]
		}  	
    end

    # NSXOrdinalsFile::getCatalystObjects()
    def self.getCatalystObjects()
    	NSXOrdinalsFile::getFileAsStructure()
    		.map{|item| NSXOrdinalsFile::structureItemToCatalystObject(item) }
    end

    # NSXOrdinalsFile::doDone(uuid)
    def self.doDone(uuid)
    	structure = NSXOrdinalsFile::getFileAsStructure()
    		.select{|item| NSXOrdinalsFile::itemToUUID(item)!=uuid }
		NSXOrdinalsFile::sendStructureToDisk(structure)    	
    end

    def NSXOrdinalsFile::setNewOrdinal(objectdescription, ordinal)
    	updatedstructure = NSXOrdinalsFile::getFileAsStructure()
    		.map{|item|
    			if item["description"]==objectdescription then
    				item["ordinal"] = ordinal
    			end
    			item
    		}
    	NSXOrdinalsFile::sendStructureToDisk(updatedstructure)
    end

end


