# encoding: utf-8

# require_relative "MiniFIFOQ.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    MiniFIFOQ::size(queueuuid)
    MiniFIFOQ::values(queueuuid)
    MiniFIFOQ::push(queueuuid, value)
    MiniFIFOQ::getFirstOrNull(queueuuid)
    MiniFIFOQ::takeFirstOrNull(queueuuid)
    MiniFIFOQ::takeWhile(queueuuid, xlambda: Element -> Boolean)
=end

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
require 'json'

# ------------------------------------------------------------------------

=begin
    queue head    : integer, index of the first element of the queue, default to 0 for a new queue
    queue length  : integer, current length of the queue, default to 0 for a new queue.
    queue indices : Array[Int] indices of queue elements
    The head and the length are both stored togehter as pair at "2b796fa5/#{queueuuid}"
    Element of index n is stored at "8d93c17a/#{queueuuid}/#{n}"
=end

# MiniFIFOQ::getElement(queueuuid, indx)
# MiniFIFOQ::setElement(queueuuid, indx, value)
# MiniFIFOQ::getQueueParametersOrNull(queueuuid)
# MiniFIFOQ::updateQueueParameters(queueuuid, params)

class MiniFIFOQ

    def self.getElement(queueuuid, indx)
        value = FKVStore::getOrDefaultValue("8d93c17a/#{queueuuid}/#{indx}", "[null]")
        JSON.parse(value).first
    end

    def self.setElement(queueuuid, indx, value)
        FKVStore::set("8d93c17a/#{queueuuid}/#{indx}", JSON.generate([value]))
    end

    def self.getQueueParametersOrNull(queueuuid)
        params = FKVStore::getOrNull("2b796fa5/#{queueuuid}")
        if params.nil? then
            [0, 0]
        else
            JSON.parse(params)
        end
    end

    def self.updateQueueParameters(queueuuid, params)
        FKVStore::set("2b796fa5/#{queueuuid}", JSON.generate(params))
    end

    # ---------------------------------------------
    # user interface

    def self.size(queueuuid)
        firstIndex, length = MiniFIFOQ::getQueueParametersOrNull(queueuuid)
        length
    end

    def self.values(queueuuid)
        firstIndex, length = MiniFIFOQ::getQueueParametersOrNull(queueuuid)
        return [] if length == 0
        (firstIndex..firstIndex+length-1).map{|indx| MiniFIFOQ::getElement(queueuuid, indx) }
    end

    def self.push(queueuuid, value)
        firstIndex, length = MiniFIFOQ::getQueueParametersOrNull(queueuuid)
        indx = firstIndex+length
        MiniFIFOQ::setElement(queueuuid, indx, value)
        MiniFIFOQ::updateQueueParameters(queueuuid, [firstIndex, length+1])
    end

    def self.getFirstOrNull(queueuuid)
        firstIndex, length = MiniFIFOQ::getQueueParametersOrNull(queueuuid)
        return nil if length == 0
        MiniFIFOQ::getElement(queueuuid, firstIndex)
    end

    def self.takeFirstOrNull(queueuuid)
        firstIndex, length = MiniFIFOQ::getQueueParametersOrNull(queueuuid)
        return nil if length == 0
        element = MiniFIFOQ::getElement(queueuuid, firstIndex)
        MiniFIFOQ::updateQueueParameters(queueuuid, [firstIndex+1, length-1])
        element
    end

    def self.takeWhile(queueuuid, xlambda)
        elements = []
        loop {
            element = MiniFIFOQ::getFirstOrNull(queueuuid)
            break if element.nil?
            break if !xlambda.call(element)
            elements << MiniFIFOQ::takeFirstOrNull(queueuuid)
        }   
        elements
    end

end

