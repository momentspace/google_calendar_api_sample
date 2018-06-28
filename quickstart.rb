require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'date'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'.freeze
CLIENT_SECRETS_PATH = 'secrets/client_secrets.json'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

##
# Ensure valid credentials, either by restoring from the saved credentials
# files or intitiating an OAuth2 authorization. If authorization is required,
# the user's default browser will be launched to approve the request.
#
# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
  token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
  authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
  user_id = 'default'
  credentials = authorizer.get_credentials(user_id)
  if credentials.nil?
    url = authorizer.get_authorization_url(base_url: OOB_URI)
    puts 'Open the following URL in the browser and enter the ' \
         'resulting code after authorization:\n' + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::CalendarV3::CalendarService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

# Fetch the next 10 events for the user
calendar_id = 'primary'
response = service.list_events(calendar_id,
                               max_results: 10,
                               single_events: true,
                               order_by: 'startTime',
                               time_min: Time.now.iso8601)
puts 'Upcoming events:'
puts 'No upcoming events found' if response.items.empty?
response.items.each do |event|
  start = event.start.date || event.start.date_time
  puts "- #{event.summary} (#{start})"
end

TIME_ZONE = 'Japan'

# 専用カレンダーを探す
calendar_id = 'private'
if File.exists?('calendar.id')
  revo_id = File.read('calendar.id')
  begin
    # event = Google::Apis::CalendarV3::Event.new(event_data)
    service.get_calendar(revo_id)
    calendar_id = revo_id
  rescue => e
    # calendar not found
    puts 'calendar was deleted.'
    exit
  end

else
  calendar = Google::Apis::CalendarV3::Calendar.new(
    summary: 'リネレボ用',
    time_zone: TIME_ZONE
  )
  result = service.insert_calendar(calendar)
  File.write('calendar.id', result.id)
  calendar_id = result.id
end

# 登録するイベント内容
start_time = DateTime.now
end_time = DateTime.now + 1
event_data = {
  summary: 'サマリ',
  description: 'description',
  location: 'location',
  start: {
    date_time: start_time.iso8601,
    time_zone: TIME_ZONE
  },
  end: {
    date_time: end_time.iso8601,
    time_zone: TIME_ZONE
  }
}


# 登録
event = Google::Apis::CalendarV3::Event.new(event_data)
response = service.insert_event(calendar_id, event)
p response

