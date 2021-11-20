
class CentralDispatch

    # CentralDispatch::access(object)
    def self.access(object)

        if object["NS198"].nil? then
            raise "[1cfff14e-dcdb-4747-ad17-bf51d27f6268: #{object}]"
        end

        if object["NS198"] == "NxBallDelegate1" then
            uuid = object["uuid"]
            NxBallsService::close(uuid, true)
            return
        end

        raise "[d8d9bb2a-d5da-4934-8146-7cc4a65dbffc: #{object}]"
    end
end