class ApplicationController < ActionController::API
  include DeviseTokenAuth::Concerns::SetUserByToken

  def ping
    render plain: "pong"
  end

  def incoming_call
    response = Twilio::TwiML::VoiceResponse.new do |r|
      r.say('hi', voice: 'alice')
      r.say('Please dont call this number.', voice: 'alice')
      r.say('If you need assistance just send a text message', voice: 'alice')
      r.say('You can also just text the word HELP and we will send you a list of commands you can text back to do a variety of things', voice: 'alice')
      r.say('Have a nice day.', voice: 'alice')
      r.say('And remember dont call this number again. Use Text instead.', voice: 'alice')
    end

    render :xml => response
  end

  def incoming_text
    puts "in incoming text with parms: #{params}"
    puts "in incoming text with twilio_params: #{twilio_params}"
    @body = twilio_params[:Body]
    @from = twilio_params[:From]
    @from = @from.sub "+1", ""
    @from = @from.sub " 1", ""
    puts "from number after stripping is #{@from}"
    puts "body is #{@body}"

    account_sid = ENV['account_sid']
    auth_token = ENV['auth_token']
    @client = Twilio::REST::Client.new account_sid, auth_token

    @club = get_club_from_message @body

    if @club.blank?
      @client.api.account.messages.create(
        from: '+16315134121',
        to: @from,
        body: "Your command must include a club name like #{Club.all.pluck(:keyword).join(',')}."
      )
      puts "club not specified in text"
      render :status => :ok
      return
    end

    @member = @club.members.find_by :phone_number => @from

    if @member.blank?
      @client.api.account.messages.create(
        from: '+16315134121',
        to: @from,
        body: "Sorry cant do anything as your number is not associated to any member"
      )
      puts "unable to find member"
      render :status => :ok
      return
    end

    # if @member.full_time == false
    #   @client.api.account.messages.create(
    #     from: '+16315134121',
    #     to: @from,
    #     body: "#{@member.name}, SMS feature is for full time members only!"
    #   )
    #   puts "found member but they are not full time"
    #   render :status => :ok
    #   return
    # end

    case @body
      when /checkin/i
        @checkin = @member.checkins.of_today.first || @member.checkins.new
        if @checkin.persisted?
          @message = "#{@member.name}, You are already checked in"
        else
          @message = "#{@member.name}, You have been checked in successfully. "
          if @member.membership_kind == 'part_time'
            @message += "Please pay your dues when you come in."
          end
        end
        @checkin.updated_at = Time.current
        @checkin.save
      when /remove/i
        @checkin = @member.checkins.of_today.first
        if @checkin.present?
          @checkin.destroy
          @message = "#{@member.name}, Your checkin has been removed!"
        else
          @message = "#{@member.name}, Your were not checked in. Nothing to do."
        end
      when /hours/i
        @message = "#{@member.name}, you are welcome to play from 7PM to 10PM"
      when /commands/i
        @message = "#{@member.name}, You can say things like: 'checkin brentwood', 'remove brentwood', 'hours of bohemia' etc."
      else
        @message = "#{@member.name}, I do not understand your Command."
    end

    @client.api.account.messages.create(
      from: '+16315134121',
      to: @from,
      body: @message,

    )
    puts "checked in successfully"
    render :status => :ok
    return

  end

  def twilio_params
    params.permit(:From, :Body)
  end

  private
  def get_club_from_message(body)
    words = body.split(" ").map(&:downcase) # [check, in, brentwood]
    Club.find_by("lower(keyword) in (?)", words)
  end
end
