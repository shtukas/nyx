# encoding: UTF-8

class InternetStatus

    # InternetStatus::setInternetOn()
    def self.setInternetOn()
        XCache::destroy("099dc001-c211-4e37-b631-8f3cf7ef6f2d")
    end

    # InternetStatus::setInternetOff()
    def self.setInternetOff()
        XCache::set("099dc001-c211-4e37-b631-8f3cf7ef6f2d", "off")
    end

    # InternetStatus::internetIsActive()
    def self.internetIsActive()
        XCache::getOrNull("099dc001-c211-4e37-b631-8f3cf7ef6f2d").nil?
    end

    # InternetStatus::markIdAsRequiringInternet(id)
    def self.markIdAsRequiringInternet(id)
        filepath = "#{Config::pathToDataCenter()}/RequireInternet/#{id}"
        FileUtils.touch(filepath)
    end

    # InternetStatus::trueIfElementRequiresInternet(id)
    def self.trueIfElementRequiresInternet(id)
        filepath = "#{Config::pathToDataCenter()}/RequireInternet/#{id}"
        File.exist?(filepath)
    end

    # InternetStatus::itemShouldShow(id)
    def self.itemShouldShow(id)
        InternetStatus::internetIsActive() or !InternetStatus::trueIfElementRequiresInternet(id)
    end
end
