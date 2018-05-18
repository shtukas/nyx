# encoding: utf-8

# require_relative "FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::size(repositorylocation or nil, queueuuid)
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeWhile(repositorylocation, queueuuid, xlambda: Element -> Boolean)
=end

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'json'

# ------------------------------------------------------------------------

=begin
    queue head    : integer, index of the first element of the queue, default to 0 for a new queue
    queue length  : integer, current length of the queue, default to 0 for a new queue.
    queue indices : Array[Int] indices of queue elements
    The head and the length are both stored togehter as pair at "2b796fa5/#{queueuuid}"
    Element of index n is stored at "8d93c17a/#{queueuuid}/#{n}"
=end

# FIFOQueue::getElement(repositorylocation or nil, queueuuid, indx)
# FIFOQueue::setElement(repositorylocation or nil, queueuuid, indx, value)
# FIFOQueue::getQueueParametersOrNull(repositorylocation or nil, queueuuid)
# FIFOQueue::updateQueueParameters(repositorylocation or nil, queueuuid, params)

class FIFOQueue

    def self.getElement(repositorylocation, queueuuid, indx)
        value = KeyValueStore::getOrDefaultValue(repositorylocation, "8d93c17a/#{queueuuid}/#{indx}", "[null]")
        JSON.parse(value).first
    end

    def self.setElement(repositorylocation, queueuuid, indx, value)
        KeyValueStore::set(repositorylocation, "8d93c17a/#{queueuuid}/#{indx}", JSON.generate([value]))
    end

    def self.getQueueParametersOrNull(repositorylocation, queueuuid)
        params = KeyValueStore::getOrNull(repositorylocation, "2b796fa5/#{queueuuid}")
        if params.nil? then
            [0, 0]
        else
            JSON.parse(params)
        end
    end

    def self.updateQueueParameters(repositorylocation, queueuuid, params)
        KeyValueStore::set(repositorylocation, "2b796fa5/#{queueuuid}", JSON.generate(params))
    end

    # ---------------------------------------------
    # user interface

    def self.size(repositorylocation, queueuuid)
        firstIndex, length = FIFOQueue::getQueueParametersOrNull(repositorylocation, queueuuid)
        length
    end

    def self.values(repositorylocation, queueuuid)
        firstIndex, length = FIFOQueue::getQueueParametersOrNull(repositorylocation, queueuuid)
        return [] if length == 0
        (firstIndex..firstIndex+length-1).map{|indx| FIFOQueue::getElement(repositorylocation, queueuuid, indx) }
    end

    def self.push(repositorylocation, queueuuid, value)
        firstIndex, length = FIFOQueue::getQueueParametersOrNull(repositorylocation, queueuuid)
        indx = firstIndex+length
        FIFOQueue::setElement(repositorylocation, queueuuid, indx, value)
        FIFOQueue::updateQueueParameters(repositorylocation, queueuuid, [firstIndex, length+1])
    end

    def self.getFirstOrNull(repositorylocation, queueuuid)
        firstIndex, length = FIFOQueue::getQueueParametersOrNull(repositorylocation, queueuuid)
        return nil if length == 0
        FIFOQueue::getElement(repositorylocation, queueuuid, firstIndex)
    end

    def self.takeFirstOrNull(repositorylocation, queueuuid)
        firstIndex, length = FIFOQueue::getQueueParametersOrNull(repositorylocation, queueuuid)
        return nil if length == 0
        element = FIFOQueue::getElement(repositorylocation, queueuuid, firstIndex)
        FIFOQueue::updateQueueParameters(repositorylocation, queueuuid, [firstIndex+1, length-1])
        element
    end

    def self.takeWhile(repositorylocation, queueuuid, xlambda)
        elements = []
        loop {
            element = FIFOQueue::getFirstOrNull(repositorylocation, queueuuid)
            break if element.nil?
            break if !xlambda.call(element)
            elements << FIFOQueue::takeFirstOrNull(repositorylocation, queueuuid)
        }   
        elements
    end

end

