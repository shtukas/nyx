# encoding: utf-8

=begin
BLxs

=end

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf(dir)

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'json'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

require_relative "Blades.rb"

# NxD001: {items: Array[Items], next: null or cache location}

# -----------------------------------------------------------------------------------

class Solingen

    # ----------------------------------------------
    # Solingen Service Private

    # Solingen::getBladeAsItem(filepath)
    def self.getBladeAsItem(filepath)
        item = {}
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        # We go through all the values in operation_unixtime order, because the one we want is the last one
        db.execute("select * from records where operation_type=? order by operation_unixtime", ["attribute"]) do |row|
            item[row["_name_"]] = JSON.parse(row["_data_"])
        end
        db.close
        item
    end

    # ----------------------------------------------
    # Solingen Service Public, Blade Bridge

    # Solingen::init(mikuType, uuid) # String : filepath
    def self.init(mikuType, uuid)
        Blades::init(mikuType, uuid)
        $SolingenManager.init(mikuType, uuid)
    end

    # Solingen::setAttribute2(uuid, attribute_name, value)
    def self.setAttribute2(uuid, attribute_name, value)
        Blades::setAttribute2(uuid, attribute_name, value)
        $SolingenManager.setAttribute2(uuid, attribute_name, value)
    end

    # Solingen::getAttributeOrNull2(uuid, attribute_name)
    def self.getAttributeOrNull2(uuid, attribute_name)
        item = Solingen::getItemOrNull(uuid)
        return nil if item.nil?
        item[attribute_name]
    end

    # Solingen::getMandatoryAttribute2(uuid, attribute_name)
    def self.getMandatoryAttribute2(uuid, attribute_name)
        value = Solingen::getAttributeOrNull2(uuid, attribute_name)
        if value.nil? then
            raise "(error: 1052d5d1-6c5b-4b58-b470-22de8b68f4c8) Failing mandatory attribute '#{attribute_name}' at blade uuid: '#{uuid}'"
        end
        value
    end

    # Solingen::addToSet2(uuid, set_name, value_id, value)
    def self.addToSet2(uuid, set_name, value_id, value)
        Blades::addToSet2(uuid, set_name, value_id, value)
    end

    # Solingen::removeFromSet2(uuid, set_name, value_id)
    def self.removeFromSet2(uuid, set_name, value_id)
        Blades::removeFromSet2(uuid, set_name, value_id)
    end

    # Solingen::getSet2(uuid, set_name)
    def self.getSet2(uuid, set_name)
        Blades::getSet2(uuid, set_name)
    end

    # Solingen::putDatablob2(uuid, datablob)  # nhash
    def self.putDatablob2(uuid, datablob)
        Blades::putDatablob2(uuid, datablob)
    end

    # Solingen::getDatablobOrNull2(uuid, nhash)
    def self.getDatablobOrNull2(uuid, nhash)
        Blades::getDatablobOrNull2(uuid, nhash)
    end

    # Solingen::destroy(uuid)
    def self.destroy(uuid)
        Blades::destroy(uuid)
        $SolingenManager.destroy(uuid)
    end

    # ----------------------------------------------
    # Solingen Service Interface, Collections

    # Solingen::mikuTypes()
    def self.mikuTypes()
        $SolingenManager.mikuTypes()
    end

    # Solingen::mikuTypeItems(mikuType)
    def self.mikuTypeItems(mikuType)
        $SolingenManager.mikuTypeItems(mikuType)
    end

    # Solingen::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        $SolingenManager.getItemOrNull(uuid)
    end

    # Solingen::getItem(uuid)
    def self.getItem(uuid)
        item = $SolingenManager.getItemOrNull(uuid)
        return item if item
        raise "Solingen::getItem(uuid) could not find item for uuid: #{uuid}"
    end

    # Solingen::mikuTypeCount(mikuType)
    def self.mikuTypeCount(mikuType)
        $SolingenManager.mikuTypeCount(mikuType)
    end
end

class SolingenAgent

    # @code
    # @folderpath
    # @foldertrace

    def initialize(code)
        @code = code
        @folderpath = "#{Blades::bladeRepository()}/#{code}"
        @packet = getPacketFromCacheOrNull()
        if @packet.nil? then
            @packet = getPacketFromDisk()
            commitPacketToCache(@packet)
        end
        maintenance()
    end

    def getItemsFromDisk()
        items = []
        LucilleCore::locationsAtFolder(@folderpath).each{|filepath|
            if Blades::isBlade(filepath) then
                uuid = Blades::getMandatoryAttribute1(filepath, "uuid")

                # First, let's compare that filepath is the recorded filepath for the uuid
                # This will enable us to detect duplicate blades and merge them

                knownFilepath = XCache::getOrNull("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}")
                if knownFilepath and File.exist?(knownFilepath) and knownFilepath != filepath then
                    filepath1 = filepath
                    filepath2 = knownFilepath
                    filepath = Blades::merge(filepath1, filepath2)
                end

                XCache::set("blades:uuid->filepath:mapping:7239cf3f7b6d:#{uuid}", filepath)

                # If a merge happened, then the file could have been moved in another folder
                # This implies that between two maintenance operations
                #    - the same item could appear in two diffrent agents
                #    - could also not be present anywhere

                items << Solingen::getBladeAsItem(filepath)
            end
        }
        items
    end

    def getItems()
        @packet["items"]
    end

    def commitPacketToCache(packet)
        XCache::set("0695fc74-095b-4dba-b9b8-e7cbea1bb1c1:#{@code}", JSON.generate(packet))
    end

    def getPacketFromCacheOrNull()
        packet = XCache::getOrNull("0695fc74-095b-4dba-b9b8-e7cbea1bb1c1:#{@code}")
        if packet then
            JSON.parse(packet)
        else
            nil
        end
    end

    def computeFolderTrace(folderpath)
        LucilleCore::locationsAtFolder(folderpath)
            .select{|filepath| Blades::isBlade(filepath) }
            .reduce(folderpath){|trace, f| Digest::SHA1.hexdigest("#{trace}:#{f}")}
    end

    def getPacketFromDisk()
        {
            "foldertrace" => computeFolderTrace(@folderpath),
            "items" => getItemsFromDisk()
        }
    end

    def cyclePacketFromDisk()
        @packet = getPacketFromDisk()
        commitPacketToCache(@packet)
    end

    def getItemOrNull(uuid)
        @packet["items"].select{|item| item["uuid"] == uuid }.first
    end

    def mikuTypes()
        @packet["items"].map{|item| item["mikuType"]}.uniq
    end

    def mikuTypeItems(mikuType)
        @packet["items"].select{|item| item["mikuType"] == mikuType }
    end

    def mikuTypeCount(mikuType)
        @packet["items"].select{|item| item["mikuType"] == mikuType }.size
    end

    def destroy(uuid)
        @packet["items"] = @packet["items"].reject{|item| item["uuid"] == uuid }
        commitPacketToCache(@packet)
    end

    def setAttribute2(uuid, attribute_name, value)
        @packet["items"] = @packet["items"].map{ |item|
            if item["uuid"] == uuid then
                item[attribute_name] = value
            end
            item
        }
        commitPacketToCache(@packet)
    end

    def init(mikuType, uuid)
        maintenance()
    end

    def maintenance()
        if computeFolderTrace(@folderpath) != @packet["foldertrace"] then
            cyclePacketFromDisk()
        end
    end
end

class SolingenManager
    def initialize()
        @agents = []
        LucilleCore::locationsAtFolder(Blades::bladeRepository())
            .map{|folderpath|
                next if !File.directory?(folderpath)
                @agents << SolingenAgent.new(File.basename(folderpath))
            }
    end

    def maintenance(s)
        @agents.each{|agent|
            agent.maintenance()
            sleep s
        }
    end

    def getItems()
        @agents.map{|agent| agent.getItems()}.flatten
    end

    def getItemOrNull(uuid)
        @agents.each{|agent| 
            item = agent.getItemOrNull(uuid)
            return item if item
        }
        nil
    end

    def mikuTypes()
        @agents.map{|agent| agent.mikuTypes()}.flatten.uniq
    end

    def mikuTypeItems(mikuType)
        @agents.map{|agent| agent.mikuTypeItems(mikuType)}.flatten
    end

    def mikuTypeCount(mikuType)
        @agents.map{|agent| agent.mikuTypeCount(mikuType)}.inject(0, :+)
    end

    def setAttribute2(uuid, attribute_name, value)
        @agents.each{|agent| 
            agent.setAttribute2(uuid, attribute_name, value)
        }
    end

    def init(mikuType, uuid)
        @agents.each{|agent| 
            agent.init(mikuType, uuid)
        }
    end

    def destroy(uuid)
        @agents.each{|agent|
            agent.destroy(uuid)
        }
    end
end

$SolingenManager = SolingenManager.new()

Thread.new {
    loop {
        sleep 120
        $SolingenManager.maintenance(1)
    }
}


