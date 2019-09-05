            NSXMultiInstancesWrite::sendEventToDisk({
                "instanceName" => NSXMiscUtils::instanceName(),
                "eventType"    => "MultiInstanceEventType:LucilleSectionDoneToday",
                "payload"      => sectionuuid
            })

            NSXMultiInstancesWrite::sendEventToDisk({
                "instanceName" => NSXMiscUtils::instanceName(),
                "eventType"    => "MultiInstanceEventType:Command-Against-ScheduleStore",
                "payload"      => {
                    "objectuuid" => objectuuid,
                    "agentuid"   => agentuid,
                    "command"    => command
                }
            })