#encoding: utf-8
#!/usr/bin/env ruby

require 'rubygems'
require 'NIFTY'
require 'dozens'
require 'net/ssh'
require 'yaml'
APP_CONFIG = YAML.load_file('setting.yaml')

#
# for Dozens
#
def check_domain(dzns, domainname)
  dzns.zones['domain'].each {|zone| return true if zone['name'] == domainname}
  return false
end

def check_record(dzns, domainname, recordname)
  return false if dzns.records(domainname).length == 0
  dzns.records(domainname)['record'].each do |record|
    return record['id'] if record['name'] == recordname + '.' + domainname
  end
  return false
end


#
# recive images list from NC
#

puts "Input Region (east-1 or west-1): "
region_name = gets

ncs4r = NIFTY::Cloud::Base.new(
  :access_key => APP_CONFIG['niftycloud']['access_key'],
  :secret_key => APP_CONFIG['niftycloud']['secret_key'],
  :server => region_name.strip! + '.cp.cloud.nifty.com',
  :path => '/api/'
  #:port => '443'
)

response = ncs4r.describe_images({})
image_list = []
response.imagesSet.item.each do |image|
  image_list.push image.imageId + " : " + image.name + "(" + image.imageOwnerAlias + ")"
end
image_list.each{|i| p i }

#
# Input new instance setting
#
puts "Select imageID: "
image_id = gets

puts "Input instance_id: "
instance_id = gets

puts "Input instance type(mini, small etc):"
type_name = gets

#puts "Input additional info:"
#additional_info = gets

#
# create new instances
#
options_for_run_instances = {
  :image_id => image_id.strip!,
  #  :additional_info          => additional_info.strip!,
  :instance_id => instance_id.strip!,
  :instance_type => type_name.strip!
}
op = APP_CONFIG['options_for_run_instances'].inject({}){|h,(k,v)| h[k.to_sym] = v; h}
options_for_run_instances.merge! op


#
# Send run request
#
startTime = Time.now
puts "Request for run instance ..."
response = ncs4r.run_instances(options_for_run_instances)

puts "LaunchTime : " + response.instancesSet.item[0].launchTime
puts "imageId : " + response.instancesSet.item[0].imageId
puts "instanceType : " + response.instancesSet.item[0].instanceType
puts "instanceId : " + response.instancesSet.item[0].instanceId

instanceId = response.instancesSet.item[0].instanceId

#
# Check state per 20 sec
#
ip = ""
t = 0
while true
  r = ncs4r.describe_instances({ :instance_id => instanceId })
  puts status = r.reservationSet.item[0].instancesSet.item[0].instanceState.name
  ip = r.reservationSet.item[0].instancesSet.item[0].dnsName
  if status == "running"
    puts "#{t} sec"
    break
  else
    t += 10
  end
  sleep 10
end

#
# Start setting shell script
#
# puts "Start set Server"

# Net::SSH.start(ip, APP_CONFIG['ssh']['user'], :keys => APP_CONFIG['ssh']['key_file_path'][region_name.strip! ], :passphrase => APP_CONFIG['ssh']['pathphrase']) do |ssh|
#  ssh.open_channel do |channel|
#    channel.exec("apt-get update; apt-get upgrade; curl #{APP_CONFIG['ssh']['sh_url']} | sh") do |ch, success|
#      raise 'コマンドが実行できません。' unless success
#      channel.on_data do |ch, data|
#        puts data
#      end
#      channel.on_process do |ch|
#        channel.eof! if channel.output.empty?
#      end
#      channel.on_close do
#        puts "done!"
#      end
#    end
#  end
#  ssh.loop
#end

#
# create Dozens record
#
puts "Regist Dozens"
dzns = Dozens::API.new(APP_CONFIG['dozens']['dznsid'], APP_CONFIG['dozens']['api_key'])
dzns.authenticate
puts Time.now
if check_domain(dzns, APP_CONFIG['options_for_create_record']['domain'])
  recordid = check_record(dzns, APP_CONFIG['options_for_create_record']['domain'], instanceId)
  if recordid
    res = dzns.update_record(recordid, { 'prio' => '', 'content' => ip, 'ttl' => ttl})
    if res['code'] == '404'
      puts "The record could not be updated."
    else
      puts "The record is updated."
    end
  else
    options = {'name' => instanceId, 'content' => ip}.merge APP_CONFIG['options_for_create_record']
    res = dzns.create_record(options)
    if res['code'] == '404'
      puts "The record could not be created."
    else
      puts 'The record is created.'
    end
  end
else
  puts 'There is no such a domain.'
end


#
# Report
#
puts "address : #{ip}"
record = Time.now - startTime
puts "#{record} sec"
rec_min = (record / 60).to_i
rec_sec = record.to_i - (rec_min * 60)
puts "TotalTime: #{rec_min.to_s} min #{rec_sec.to_s} sec"

# Display test app (MacOSX only)
#puts "http://#{instanceId}.#{APP_CONFIG['options_for_create_record']['domain']}:8080/books"
#exec('open http://' + instanceId +'.' + APP_CONFIG['options_for_create_record']['domain'] + ':8080/books')
