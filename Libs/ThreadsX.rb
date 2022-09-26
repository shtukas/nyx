
class ThreadsX

    # ThreadsX::startViennaImport()
    def self.startViennaImport()
        Thread.new {
            loop {
                sleep 600
                system("#{File.dirname(__FILE__)}/operations/vienna-import")
            }
        }
    end

    # ThreadsX::nxBallsMonitoringAndNotification()
    def self.nxBallsMonitoringAndNotification()
        Thread.new {
            loop {
                sleep 60

                NxBallsIO::nxballs().each{|nxball|
                    NxBallsService::marginCallIfIsTime(nxball["uuid"])
                }

                NxBallsIO::nxballs().each{|nxball|
                    next if nxball["status"]["type"] != "running"
                    timespan = Time.new.to_f - nxball["status"]["thisSprintStartUnixtime"]
                    if timespan > nxball["desiredBankedTimeInSeconds"] then
                        CommonUtils::onScreenNotification("Catalyst", "NxBall over running")
                    end
                }
                
            }
        }
    end

    # ThreadsX::outBufferToCommsLine()
    def self.outBufferToCommsLine()
        Thread.new {
            loop {
                sleep 10
                if SystemEventsBuffering::shouldPublishBufferNow() then
                    SystemEventsBuffering::outBufferToCommsLine()
                end
            }
        }
    end

    # ThreadsX::refreshTodosActivePool()
    def self.refreshTodosActivePool()
        Thread.new {
            sleep 300
            if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("ec3f3f57-ff52-412c-9257-351e5345df8e", 86400) then # once every day
                NxTodosActivePool::commitPoolToCache(NxTodosActivePool::computeActivePool())
            end
        }
    end
end
