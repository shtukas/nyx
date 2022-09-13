
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

    # ThreadsX::startNxBallsMonitoringAndNotification()
    def self.startNxBallsMonitoringAndNotification()
        Thread.new {
            loop {
                sleep 60

                NxBallsIO::nxballs().each{|nxball|
                    NxBallsService::marginCallIfIsTime(nxball["uuid"])
                }

                NxBallsIO::nxballs().each{|nxball|
                    next if nxball["status"]["type"] != "running"

                    realisedTimeInSeconds = nxball["status"]["bankedTimeInSeconds"]
                    unrealiseTimeInSeconds = Time.new.to_i - nxball["status"]["lastMarginCallUnixtime"]
                    currentTotalTimeInSeconds = realisedTimeInSeconds + unrealiseTimeInSeconds

                    if currentTotalTimeInSeconds > (nxball["desiredBankedTimeInSeconds"] || 3600) then
                        CommonUtils::onScreenNotification("Catalyst", "NxBall over running")
                    end
                }
                
            }
        }
    end

    # ThreadsX::startCommsLineOps()
    def self.startCommsLineOps()
        Thread.new {
            loop {
                # We use a programmable boolean because we want to remain consistent across restarts
                if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("6ba54135-fa9b-43c5-aa2f-eeb3dd09e16f", 600) then # 10 mins
                    SystemEvents::publishSystemEventsOutBuffer()
                end
                sleep 60
            }
        }
    end
end
