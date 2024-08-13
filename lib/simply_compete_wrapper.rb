# client = SimplyCompeteWrapper.new 'gallian83@hotmail.com', 'bttc', 1017
# client.setup_session
# x = client.download_csv
require 'csv'

class SimplyCompeteWrapper

  AUTH_URL = 'https://usatt.simplycompete.com/j_spring_security_check'
  RATINGS_URL_PREFIX = 'https://usatt.simplycompete.com/l/downloadRatings'

  def initialize(username, password, league_id)
    @username=username
    @password=password
    @league_id=league_id
    @session_id = nil
  end

  def setup_session
    form_data = {
      j_username: @username,
      j_password: @password,
    }

    headers = {
        'Referer' => 'http://localhost:3000/#/clubs/1/members',
        'Content-Type' => 'application/x-www-form-urlencoded',
        'Accept' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/json'
      }

    RestClient::Request.execute(method: 'POST', url: AUTH_URL, payload: form_data, headers: headers) do |response|
      puts "got response headers"
      puts response.headers
      puts response.body
      if response.headers[:location] =~ /authfail/
        puts "login failure"
      else
        puts "login successful"
        @session_id = response.cookies["JSESSIONID"]
        puts "got session id"
        puts @session_id
      end
    end
    puts "request"
  end

  def download_csv
    url = "#{RATINGS_URL_PREFIX}/#{@league_id}"
    headers = {
      cookies: {
        JSESSIONID: @session_id
      }
    }
    response = RestClient::Request.execute(method: 'POST', url: url, headers: headers)
    puts response
    csv = ::CSV.parse(response.body, :headers => true).reject { |row| row.all?(&:nil?) }.map(&:to_hash)
    csv = csv.each_with_object({}) do |h, obj|
      key = h["FirstName"]+" "+h["LastName"]
      if h["LeagueRating"].blank?
         h["LeagueRating"] = '0'
      end
      if h["Expiration"].blank?
         h["Expiration"] = '01/01/1990'
      end
      if h["MemberID"].blank?
         h["MemberID"] = '0'
      end
      value = h["LeagueRating"] +"|"+h["Expiration"]+"|"+h["MemberID"]
      obj[key] = value
    end
    csv
  end

end
