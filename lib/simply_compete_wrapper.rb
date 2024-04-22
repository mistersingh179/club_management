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
    RestClient::Request.execute(method: 'POST', url: AUTH_URL, payload: form_data) do |response|
      puts response.headers
      if response.headers[:location] =~ /authfail/
        puts "login failure"
      else
        puts "login successful"
        @session_id = response.cookies["JSESSIONID"]
        puts @session_id
      end
    end
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
