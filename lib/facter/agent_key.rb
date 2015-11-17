require 'facter'
require 'net/http'
require 'uri'

Facter.add(:sd_agent_key, :timeout => 10) do

    # just in case we don't get any of them
    result = nil

    # We inject this file using the Rackspace api
    # on instance creation
    # do this first as it's fast
    if File::exist?('/etc/sd-agent-key')
        result = Facter::Util::Resolution.exec("cat /etc/sd-agent-key")
    elsif Facter.value('ec2_instance_id')
        # use the amazon metadata api to
        # get user-data that we've set on
        # instance creation
        uri = URI("http://ec2meta.serverdensity.com/latest/user-data")
        req = Net::HTTP::Get.new(uri.request_uri)
        res = Net::HTTP.start(uri.host, uri.port) {|http|
                http.request(req)
            }
        
        result = res.body.split(':').last if res.code == 200
    end

    # If the configuration file exists and has a valid agent_key use it
    if File::exist?('/etc/sd-agent/config.cfg')
        agent_key_line = File.foreach('/etc/sd-agent/config.cfg').find {|l| l.include?("agent_key")}
        agent_key = agent_key_line.split(':').last.strip
        # String.hex returns 0 if String is an invalid hex number
        if agent_key.hex > 0
            result = agent_key
        else
            result = nil
        end
    end

    # if we get to here and neither of the above
    # methods have worked
    # the custom function will use the api to create
    # a new device, rather than matching to an existing one

    setcode { result }
end
