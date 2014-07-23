
log = Logger.new(STDOUT)
jenkins_host = 'build.vistacore.us'
port = 443

last_builds = {}

SCHEDULER.every '15s', first_in: 0 do |foo|
  http = Net::HTTP.new(jenkins_host, port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  # more selective url: /view/ehmp/api/json?pretty=true&depth=1&tree=views[jobs[name,url,color]]
  response = http.request(Net::HTTP::Get.new('/api/json'))
  jobs = JSON.parse(response.body)['jobs']

  builds = []

  matches = %w(
    ehmp-acceptance-test-build-next
    ehmp-integration-test-build-next
    ehmp-deploy-demo-build-next
    ehmp-dev-build-next
    ehmp-infrastructure-codequality
    ehmp-performance-test-build-next
    ehmp-ui-dev-build-next
    adk-acceptance-test-build-next
    adk-dev-build-next
    rdk-acceptance-test-build-next
    rdk-integration-test-build-next
    rdk-dev-build-next
    rdk-infrastructure-build-next
  )

  jobs.select { |j| matches.include?(j['name']) }.map! do |job|
    name = job['name']
    # other health reports: /job/#{name}/api/json?pretty=true&tree=healthReport[description,iconUrl,score]
    coverage_path = "/job/#{name}/lastBuild/cobertura/api/json?depth=2&tree=results[elements[name,ratio]]"
    last_success_path = "/job/#{name}/lastSuccessfulBuild/api/json"

    response = http.request(Net::HTTP::Get.new(coverage_path))
    coverage = nil
    if response.code == '200'
      elements = JSON.parse(response.body)['results']['elements']
      elements.map! do |element|
        coverage = element['ratio'] if element['name'] == 'Conditionals'
      end
    end

    response = http.request(Net::HTTP::Get.new(last_success_path))
    if response.code == '200'
      elapsed_minutes = JSON.parse(response.body)['duration'] / 60_000
    end

    # Corrections for Jenkins icon customization
    icon = job['color'].gsub('disabled', 'grey').gsub('aborted', 'grey')
    color = job['color'].gsub('blue', 'green').gsub('red_anime', 'red').gsub('gray_anime', 'gray').gsub('green_anime', 'green').gsub('aborted_anime', 'gray')

    status = case icon
             when 'red' then 'Failed'
             when 'blue' then 'Success'
             when 'green' then 'Success'
             when 'yellow' then 'Unstable'
             when 'disabled' then 'Disabled'
             when 'aborted' then 'Aborted'
             when 'blue_anime' then 'Building'
             when 'green_anime' then 'Building'
             when 'red_anime' then 'Building'
             when 'grey_anime' then 'Building'
             when 'aborted_anime' then 'Building'
             when 'yellow_anime' then 'Building'
             else 'Failure'
           end

    # Other attributes in json API:
    # icon_url = job['healthReport'][0]['iconUrl']
    # img_path = '/static/foo/images/48x48/'
    # health_url = "#{jenkins_host}:#{port}#{img_path}#{icon_url}"
    # desc = job['description']
    health_url = "https://build.vistacore.us/static/12429cfa/images/48x48/#{icon}.#{icon =~ /anime/ ? 'gif' : 'png'}"

    build = {
      name: name,
      status: status,
      health: health_url,
      color: color,
      desc: 'Description',
      coverage: coverage ? coverage.to_i.to_s + '%' : '',     # convert to whole number string
      elapsed: elapsed_minutes ? elapsed_minutes.to_s + ' min' : ''
    }
    builds << build
  end

  if builds != last_builds
    log.debug builds
    last_builds = builds
    send_event('jenkins', items: builds)
  end
end
