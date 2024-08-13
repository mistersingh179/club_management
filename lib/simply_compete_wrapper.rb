require 'rest-client'
require 'nokogiri'
require 'csv'

class SimplyCompeteWrapper

  LOGIN_URL = 'https://usatt.simplycompete.com/login/auth'
  XHR_AUTH_URL = 'https://usatt.simplycompete.com/login/xhrAuth'
  RATINGS_URL_PREFIX = 'https://usatt.simplycompete.com/l/downloadRatings'

  def initialize(username, password, league_id)
    @username = username
    @password = password
    @league_id = league_id
    @session_id = nil
    @csrf_token = nil
  end

  def setup_session
    # Fetch the login page to retrieve the CSRF token
    response = RestClient.get(LOGIN_URL)
    @session_id = response.cookies["JSESSIONID"]
    puts "got @session_id: #{@session_id}"

    html_doc = Nokogiri::HTML(response.body)
    # Extract CSRF token from the script tag
    script_tag_content = html_doc.xpath('//script[contains(text(), "window.csrf")]').text
    csrf_match = script_tag_content.match(/window\.csrf\s*=\s*'([^']+)'/)

    if csrf_match
      @csrf_token = csrf_match[1]
      puts "CSRF token retrieved: #{@csrf_token}"
    else
      raise "CSRF token not found"
    end
    # Perform the login with the CSRF token
    form_data = {
      username: @username,
      password: @password,
      c: @csrf_token,
    }
    headers = {
      cookies: {
        JSESSIONID: @session_id
      }
    }

    login_response = RestClient::Request.execute(method: 'POST', url: XHR_AUTH_URL, payload: form_data, headers: headers) do |response|
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
    puts login_response
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
      key = h["FirstName"] + " " + h["LastName"]
      h["LeagueRating"] ||= '0'
      h["Expiration"] ||= '01/01/1990'
      h["MemberID"] ||= '0'
      value = h["LeagueRating"] + "|" + h["Expiration"] + "|" + h["MemberID"]
      obj[key] = value
    end
    csv
  end

end
