
# encoding: UTF-8

class DataStoresOrchestration

    # DataStoresOrchestration::pushUp()
    def self.pushUp()
        # ------------------------------------------------------------------------------------
        raise "[error: 94099c52]" if !Realms::isDocnet()
        raise "[error: 655ed32a]" if !Realms::primaryDataStoreFolderPath().include?(".docnet")
        raise "[error: e7236edb]" if !Realms::primaryDataStoreFolderPath().include?("002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93")
        # I confirm, we really do not want this to run against the catalyst primary data store
        # ------------------------------------------------------------------------------------
        DeskOperator::commitDeskChangesToPrimaryRepository()
        DataStore2DataStore3DirectionalSyncs::store2ToStore3Update()
        DataStore3RemoteControl::doSynchronizeRepositoryData()
    end

    # DataStoresOrchestration::pullDown()
    def self.pullDown()
        # ------------------------------------------------------------------------------------
        raise "[error: d4fb0754]" if !Realms::isDocnet()
        raise "[error: 76109b74]" if !Realms::primaryDataStoreFolderPath().include?(".docnet")
        raise "[error: 1660e1ce]" if !Realms::primaryDataStoreFolderPath().include?("002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93")
        # I confirm, we really do not want this to run against the catalyst primary data store
        # ------------------------------------------------------------------------------------
        DeskOperator::commitDeskChangesToPrimaryRepository()
        DataStore3RemoteControl::doSynchronizeRepositoryData()
        DataStore2DataStore3DirectionalSyncs::store3ToStore2Update()
        # NyxObjects CacheKey Update
    end

    # DataStoresOrchestration::fullSync()
    def self.fullSync()
        # ------------------------------------------------------------------------------------
        raise "[error: c66979a4]" if !Realms::isDocnet()
        raise "[error: 9cc84b2c]" if !Realms::primaryDataStoreFolderPath().include?(".docnet")
        raise "[error: 40ff622f]" if !Realms::primaryDataStoreFolderPath().include?("002-primary-store-949658fc-5474-45cf-b754-ab2500a89a93")
        # I confirm, we really do not want this to run against the catalyst primary data store
        # ------------------------------------------------------------------------------------
        DeskOperator::commitDeskChangesToPrimaryRepository()
        DataStore2DataStore3DirectionalSyncs::store2ToStore3Update()
        DataStore3RemoteControl::doSynchronizeRepositoryData()
        DataStore2DataStore3DirectionalSyncs::store3ToStore2Update()
        # NyxObjects CacheKey Update
    end

end
