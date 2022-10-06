class DataStore3CAObjects

    # DataStore3CAObjects::getObject(nhash)
    def self.getObject(nhash)
        if $TheLibrarianInMemoryObjectCache[nhash] then
            return $TheLibrarianInMemoryObjectCache[nhash]
        end
        object = 
            JSON.parse(
                IO.read(
                    DataStore1::acquireNearestFilepathForReadingErrorIfNotAcquisable(nhash, true)
                )
            )
        $TheLibrarianInMemoryObjectCache[nhash] = object
        return object
    end

    # DataStore3CAObjects::setObject(object) # nhash
    def self.setObject(object)
        DataStore1::putDataByContent(JSON.generate(object))
    end
end
