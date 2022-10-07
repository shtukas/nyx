class DataStore3CAObjects

    # DataStore3CAObjects::getObject(nhash)
    def self.getObject(nhash)
        object = 
            JSON.parse(
                IO.read(
                    DataStore1::getNearestFilepathForReadingErrorIfNotAcquisable(nhash, true)
                )
            )
    end

    # DataStore3CAObjects::setObject(object) # nhash
    def self.setObject(object)
        DataStore1::putDataByContent(JSON.generate(object))
    end
end
