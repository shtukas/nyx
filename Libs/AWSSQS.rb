
# encoding: UTF-8

require 'aws-sdk-sqs'
require 'aws-sdk-sts'

class AWSSQS

    # AWSSQS::sqs_url_or_null(machinesource, machinetarget)
    def self.sqs_url_or_null(machinesource, machinetarget)
        if machinesource == "Lucille18" and machinetarget == "Lucille20" then
            return Config::get("aws.SQS.URL.Lucille18ToLucille20")
        end
        if machinesource == "Lucille20" and machinetarget == "Lucille18" then
            return Config::get("aws.SQS.URL.Lucille20ToLucille18")
        end
        nil
    end

    # AWSSQS::sendEventToTheOtherMachine(event)
    def self.sendEventToTheOtherMachine(event)
        Aws.config.update({
           credentials: Aws::Credentials.new(Config::get("aws.AWS_ACCESS_KEY_ID"), Config::get("aws.AWS_SECRET_ACCESS_KEY"))
        })
        region = 'eu-west-1'

        machinesource = Machines::thisMachine()
        machinetarget = Machines::theOtherMachine()

        sqs_url = AWSSQS::sqs_url_or_null(machinesource, machinetarget)

        if sqs_url.nil? then
            puts "Could not determine queue url"
            return
        end

        sqs_client = Aws::SQS::Client.new(region: region)

        begin 
            sqs_client.send_message(
                queue_url: sqs_url,
                message_body: JSON.generate(event)
            )
        rescue StandardError => e
            puts "Error sending messages: #{e.message}"
        end
    end

end
