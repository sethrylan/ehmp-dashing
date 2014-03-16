require "net/https"
 
jenkins_host = 'build.vistacore.us'
img_path = '/static/foo/images/48x48/'
port = 443

last_builds = {}

SCHEDULER.every '10s', :first_in => 0 do |foo|
  http = Net::HTTP.new(jenkins_host, port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  response = http.request(Net::HTTP::Get.new("/api/json"))
  jobs = JSON.parse(response.body)["jobs"]

  builds = []

  jobs.select{|j| j['name']=~/ehmp/}.map! do |job|
    name = job['name']
    # cov_path = "/job/#{name}/lastBuild/cobertura/api/json?depth=2"
    # response = http.request(Net::HTTP::Get.new(cov_path))
    # coverage = nil
    # if response.code == '200'
    #   elements = JSON.parse(response.body)['results']['elements']
    #   elements.map! do |element|
    #     if element['name'] == 'Conditionals'
    #       coverage = element['ratio']
    #     end
    #   end
    # end
    coverage = 0.20

    color = job['color'].gsub('blue', 'green').gsub('disabled', 'grey')
    icon = job['color'].gsub('disabled', 'grey')

    status = case color
               when 'red' then 'Failed'
               when 'green' then 'Success'
               when 'yellow' then 'Unstable'
               when 'disabled' then 'Disabled'
               when 'grey' then 'Disabled'
               when 'aborted' then 'Aborted'
               when 'green_anime' then 'Building'
               when 'red_anime' then 'Building'
               when 'gray_anime' then 'Building'
               when 'aborted_anime' then 'Building'
               when 'yellow_anime' then 'Building'
               else 'Failure'
             end
    # status = 'Success'
    # icon_url = job['healthReport'][0]['iconUrl']
    # health_url = "#{jenkins_host}:#{port}#{img_path}#{icon_url}"
    health_url = "https://build.vistacore.us/static/12429cfa/images/48x48/#{icon}.png"
    # desc = job['description']
    desc = 'Description'

    build = {
      name: name, status: status, health: health_url, color: color
    }
    desc.empty? || build['desc'] = desc
    coverage && build['coverage'] = coverage.to_i.to_s + '%'
    builds << build
  end

  if builds != last_builds
    puts builds
    last_builds = builds
    send_event('jenkins', { items: builds })
  end
end
