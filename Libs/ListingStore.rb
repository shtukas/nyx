# encoding: UTF-8

class ListingStore

    def initialize() # : Integer
        @items = []
    end

    def register(item)
        cursor = @items.size
        @items << item
        @items.size-1
    end

    def prefixString()
        indx = @items.size-1
        "#{"%3d" % indx}"
    end

    def get(indx)
        @items[indx].clone
    end
end
