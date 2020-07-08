
# require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

# ---------------------------------------------------------------------------------------------

require 'json'

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "1ac4eb69"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

# ---------------------------------------------------------------------------------------------

=begin

TreeNode 
{
    "locationKey"           : String this is the location key of the object itself. This allows us to update its value directly
    "nodeuuid"              : String # Hash of the valueuuid
    "nodevalue"             : nil or value
    "leftChildLocationKey"  : nil | String
    "rightChildLocationKey" : nil | String
}

=end

class BTreeSetsInternals

    # BTreeSetsInternals::getRootNodeLocationKey(setuuid)
    def self.getRootNodeLocationKey(setuuid)
        Digest::SHA1.hexdigest("#{setuuid}:5055b164-33ea-432f-9539-37277a6633a3") # Do not change this value
    end

    # BTreeSetsInternals::getRootNode(repositorylocation, setuuid)
    def self.getRootNode(repositorylocation, setuuid)
        rootkey = BTreeSetsInternals::getRootNodeLocationKey(setuuid)
        treenode = KeyValueStore::getOrNull(repositorylocation, rootkey)
        return JSON.parse(treenode) if treenode
        treenode = {
            "locationKey"           => rootkey,
            "nodeuuid"              => SecureRandom.hex,
            "nodevalue"             => nil,
            "leftChildLocationKey"  => nil,
            "rightChildLocationKey" => nil
        }
        KeyValueStore::set(repositorylocation, treenode["locationKey"], JSON.generate(treenode))
        treenode
    end

    # BTreeSetsInternals::recursivelyExtractTreeNodeOrNull(repositorylocation, nextLocationKeyToLookAt, nodeuuid)
    def self.recursivelyExtractTreeNodeOrNull(repositorylocation, nextLocationKeyToLookAt, nodeuuid)
        #puts "BTreeSetsInternals::recursivelyExtractTreeNodeOrNull(#{repositorylocation}, #{nextLocationKeyToLookAt}, #{nodeuuid})"
        treenode = KeyValueStore::getOrNull(repositorylocation, nextLocationKeyToLookAt)
        return nil if treenode.nil?
        treenode = JSON.parse(treenode)
        if treenode["nodeuuid"] == nodeuuid then
            return treenode
        end
        if (treenode["nodeuuid"] < nodeuuid) and treenode["rightChildLocationKey"] then
            # We look at the right child, which contains higher nodeuuids
            return BTreeSetsInternals::recursivelyExtractTreeNodeOrNull(repositorylocation, treenode["rightChildLocationKey"], nodeuuid)
        end
        if (treenode["nodeuuid"] > nodeuuid) and treenode["leftChildLocationKey"] then
            # We look at the left child, which contains lower nodeuuids
            return BTreeSetsInternals::recursivelyExtractTreeNodeOrNull(repositorylocation, treenode["leftChildLocationKey"], nodeuuid)            
        end
        nil
    end

    # BTreeSetsInternals::recursivelyExtractValues(repositorylocation, nextLocationKeyToLookAtOrNull): Array[Value]
    def self.recursivelyExtractValues(repositorylocation, nextLocationKeyToLookAtOrNull)
        return [] if nextLocationKeyToLookAtOrNull.nil?
        treenode = KeyValueStore::getOrNull(repositorylocation, nextLocationKeyToLookAtOrNull)
        return [] if treenode.nil?
        treenode = JSON.parse(treenode)
        ( [ treenode["nodevalue"] ] + BTreeSetsInternals::recursivelyExtractValues(repositorylocation, treenode["leftChildLocationKey"]) + BTreeSetsInternals::recursivelyExtractValues(repositorylocation, treenode["rightChildLocationKey"]) ).compact
    end

    # BTreeSetsInternals::putValue(repositorylocation, focusTreeNode, nodeuuid, value)
    def self.putValue(repositorylocation, focusTreeNode, nodeuuid, value)
        #puts "BTreeSetsInternals::putValue(#{repositorylocation}, #{focusTreeNode}, #{nodeuuid}, #{value})"
        if focusTreeNode["nodeuuid"] == nodeuuid then
            focusTreeNode["nodevalue"] = value
            KeyValueStore::set(repositorylocation, focusTreeNode["locationKey"], JSON.generate(focusTreeNode))
            return
        end
        if focusTreeNode["nodeuuid"] < nodeuuid then
            # We put the value on the right hand side of the node, we might have to actually create the child
            if focusTreeNode["rightChildLocationKey"] then
                treenode = KeyValueStore::getOrNull(repositorylocation, focusTreeNode["rightChildLocationKey"])
                if treenode.nil? then
                    puts "TreeSets: condition e359b4cd, this is not supposed to happen. Exiting."
                    exit
                end
                treenode = JSON.parse(treenode)
                BTreeSetsInternals::putValue(repositorylocation, treenode, nodeuuid, value)
            else
                treenode = {
                    "locationKey"           => SecureRandom.hex,
                    "nodeuuid"              => nodeuuid,
                    "nodevalue"             => value,
                    "leftChildLocationKey"  => nil,
                    "rightChildLocationKey" => nil
                }
                KeyValueStore::set(repositorylocation, treenode["locationKey"], JSON.generate(treenode))
                focusTreeNode["rightChildLocationKey"] = treenode["locationKey"]
                KeyValueStore::set(repositorylocation, focusTreeNode["locationKey"], JSON.generate(focusTreeNode))
            end
        end
        if focusTreeNode["nodeuuid"] > nodeuuid then
            # We put the value on the right hand side of the node, we might have to actually create the child
            if focusTreeNode["leftChildLocationKey"] then
                treenode = KeyValueStore::getOrNull(repositorylocation, focusTreeNode["leftChildLocationKey"])
                if treenode.nil? then
                    puts "TreeSets: condition 7cb1afba, this is not supposed to happen. Exiting."
                    exit
                end
                treenode = JSON.parse(treenode)
                BTreeSetsInternals::putValue(repositorylocation, treenode, nodeuuid, value)
            else
                treenode = {
                    "locationKey"           => SecureRandom.hex,
                    "nodeuuid"              => nodeuuid,
                    "nodevalue"             => value,
                    "leftChildLocationKey"  => nil,
                    "rightChildLocationKey" => nil
                }
                KeyValueStore::set(repositorylocation, treenode["locationKey"], JSON.generate(treenode))
                focusTreeNode["leftChildLocationKey"] = treenode["locationKey"]
                KeyValueStore::set(repositorylocation, focusTreeNode["locationKey"], JSON.generate(focusTreeNode))
            end            
        end
    end

end

BTREESETS_XSPACE_XCACHE_FOLDER_PATH = "/Users/pascal/x-space/x-cache"

class BTreeSets

    # BTreeSets::values(repositorylocation, setuuid)
    def self.values(repositorylocation, setuuid)
        if repositorylocation.nil? then
            repositorylocation = BTREESETS_XSPACE_XCACHE_FOLDER_PATH
        end
        setuuid = Digest::SHA1.hexdigest("#{setuuid}:0d4d74b4-fa35-41c9-8feb-a10500fe4f84") # Do not change this value
        rootLocationKey = BTreeSetsInternals::getRootNodeLocationKey(setuuid)
        BTreeSetsInternals::recursivelyExtractValues(repositorylocation, rootLocationKey)
    end

    # BTreeSets::set(repositorylocation, setuuid, valueuuid, value)
    def self.set(repositorylocation, setuuid, valueuuid, value) 
        if repositorylocation.nil? then
            repositorylocation = BTREESETS_XSPACE_XCACHE_FOLDER_PATH
        end
        setuuid = Digest::SHA1.hexdigest("#{setuuid}:0d4d74b4-fa35-41c9-8feb-a10500fe4f84") # Do not change this value
        nodeuuid = Digest::SHA1.hexdigest("#{valueuuid}:7b8632b1-2cfa-4568-9c1a-dfa7c8c8b091") # Do not change this value
        rootNode = BTreeSetsInternals::getRootNode(repositorylocation, setuuid)
        BTreeSetsInternals::putValue(repositorylocation, rootNode, nodeuuid, value)
    end

    # BTreeSets::getOrNull(repositorylocation, setuuid, valueuuid)
    def self.getOrNull(repositorylocation, setuuid, valueuuid)
        if repositorylocation.nil? then
            repositorylocation = BTREESETS_XSPACE_XCACHE_FOLDER_PATH
        end
        setuuid = Digest::SHA1.hexdigest("#{setuuid}:0d4d74b4-fa35-41c9-8feb-a10500fe4f84") # Do not change this value
        nodeuuid = Digest::SHA1.hexdigest("#{valueuuid}:7b8632b1-2cfa-4568-9c1a-dfa7c8c8b091") # Do not change this value
        nextLocationKeyToLookAt = BTreeSetsInternals::getRootNodeLocationKey(setuuid)
        treenode = BTreeSetsInternals::recursivelyExtractTreeNodeOrNull(repositorylocation, nextLocationKeyToLookAt, nodeuuid)
        return nil if treenode.nil?
        treenode["nodevalue"]
    end

    # BTreeSets::destroy(repositorylocation, setuuid, valueuuid)
    def self.destroy(repositorylocation, setuuid, valueuuid) 
        if repositorylocation.nil? then
            repositorylocation = BTREESETS_XSPACE_XCACHE_FOLDER_PATH
        end
        setuuid = Digest::SHA1.hexdigest("#{setuuid}:0d4d74b4-fa35-41c9-8feb-a10500fe4f84") # Do not change this value
        nodeuuid = Digest::SHA1.hexdigest("#{valueuuid}:7b8632b1-2cfa-4568-9c1a-dfa7c8c8b091") # Do not change this value
        nextLocationKeyToLookAt = BTreeSetsInternals::getRootNodeLocationKey(setuuid)
        treenode = BTreeSetsInternals::recursivelyExtractTreeNodeOrNull(repositorylocation, nextLocationKeyToLookAt, nodeuuid)
        return if treenode.nil?
        treenode["nodevalue"] = nil
        KeyValueStore::set(repositorylocation, treenode["locationKey"], JSON.generate(treenode))
    end

end

