# require 'net/http'
# require 'json'
# require 'time'

# ################## 
# #widget constants
# ################## 

# #Jenkins server base URL
# JENKINS_URI = URI.parse("https://build.vistacore.us")

# #change to true if Jenkins is using SSL
# JENKINS_USING_SSL = true

# #credentials of Jenkins user (give these values if the above flag is true)
# JENKINS_AUTH = {
#   'name' => nil,
#   'password' => nil
# }

# #Jenkins job name to be monitored
# JENKINS_JOB_TO_BE_MONITORED = 'ehmp-dev-build-next'

# #Trim thresholds (widget display)
# COMMIT_MESSAGE_TRIM_LENGTH = 120
# FILE_LIST_TRIM_LENGTH = 4


# #helper function which fetches JSON for job changeset
# def get_json_for_job_changeset(job_name, build = 'lastBuild')
#   job_name = URI.encode(job_name)
#   http = Net::HTTP.new(JENKINS_URI.host, JENKINS_URI.port)
  
#   request = Net::HTTP::Get.new("/job/#{job_name}/#{build}/api/json?tree=changeSet[items[kind,commitId,date,msg,affectedPaths,author[fullName]]]")
  
#   #check if Jenkins is implementing SSL
#   if JENKINS_USING_SSL == true
#     http.use_ssl = true
#     http.verify_mode = OpenSSL::SSL::VERIFY_NONE
#   end
  
#   if JENKINS_AUTH['name']
#     request.basic_auth(JENKINS_AUTH['name'], JENKINS_AUTH['password'])
#   end
#   response = http.request(request)
#   JSON.parse(response.body)
# end


# #scheduled job
# SCHEDULER.every '15s' do
#   commit_info = get_json_for_job_changeset(JENKINS_JOB_TO_BE_MONITORED)
#   commit_items = commit_info["items"]
  
#   # check if the "items" array item contains elements
#   # Note: "items" may be empty, for example when Jenkins is in the process of building the 
#   # job which is being monitored for changes
#   if !commit_info["changeSet"]["items"].empty?
   
#     #check if we're dealing with git
#     if commit_info["changeSet"]["kind"] == 'git'
#       commit_id = commit_info["changeSet"]["items"][0]["commitId"]
#       commit_date = commit_info["changeSet"]["items"][0]["date"]
#     else
#       #not using git - fall back to Perforce JSON structure
#       commit_id = commit_info["changeSet"]["items"][0]["changeNumber"]
#       commit_date = commit_info["changeSet"]["items"][0]["changeTime"]
#     end
    
#     #extract commit information fields from Jenkins JSON response
#     author_name = commit_info["changeSet"]["items"][0]["author"]["fullName"]
    
#     #process commit message
#     commit_message = commit_info["changeSet"]["items"][0]["msg"]

#     #trim message length if necessary
#     if commit_message.length > COMMIT_MESSAGE_TRIM_LENGTH
#       commit_message = commit_message.to_s[0..COMMIT_MESSAGE_TRIM_LENGTH].gsub(/[^\w]\w+\s*$/, ' ...')
#     end
    
#     #build up list of affected files
#     file_items = commit_info["changeSet"]["items"][0]["affectedPaths"]
#     affected_items = Array.new
    
#     #add key-value pair for each file found
#     file_items.sort.each { |x| affected_items.push( {:file_name => x} ) }
    
#     #trim file list length if necessary
#     if affected_items.length > FILE_LIST_TRIM_LENGTH
#       length = affected_items.length
#       affected_items = affected_items.slice(0, FILE_LIST_TRIM_LENGTH)
      
#       #add indication of total number of affected files
#       affected_items[FILE_LIST_TRIM_LENGTH] = {:file_name => '  ...  (' + length.to_s + ' files in total)'}
#     end
    
#     json_formatted_data = Hash.new
#     json_formatted_data[0] = { id: commit_id, timestamp: commit_date, message: commit_message, author: author_name }
    
#     puts json_formatted_data

#     #send event to dashboard
#     send_event('jenkins-last-commit', commit_entries: json_formatted_data.values, commit_files: affected_items)
  
#   else
#     #Jenkins is busy
#     print "[changeSet] JSON object doesn't contain data ... \n"
#   end
# end
