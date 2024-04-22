class OpenController < ApplicationController

  before_action :set_club, only: [:checkin, :remove_checkin, :list_checkins]
  before_action :set_member, only: [:checkin, :remove_checkin]

  def clubs
    @clubs = Club.all
    puts @clubs
    render :json => @clubs
  end

  def checkin

    @checkin = @member.checkins.of_today.first || @member.checkins.new
    status = @checkin.persisted? ? 208 : 201
    @checkin.updated_at = Time.current

    if @checkin.save
      render json: @checkin.to_json(
          :include => {
              :member => {
                  :include => {
                      :checkins => {
                          :only => :id
                      }
                  },
                  :only => [:id, :table_number]
              }
          }
      ), status: status
    else
      render json: @checkin.errors, status: :unprocessable_entity
    end
  end

  def remove_checkin
    @checkin = @member.checkins.of_today.first
    if @checkin && @checkin.destroy
      render json: {message: "success"}, status: 200
    else
      render json: {message: "unable to remove check-in"}, status: :unprocessable_entity
    end

  end

  def list_checkins
    @members = @club.members.joins(:checkins).
        where("checkins.created_at > ? and checkins.created_at < ?",
              Time.current.beginning_of_day, Time.current.end_of_day)

    render json: @members, only: [:id, :name, :league_rating, :table_number]

  end

  private

  def set_club
    if params[:club_id].present?
      @club = Club.where(:id => params[:club_id]).first
    else
      @club = nil
    end
    puts @club
    if @club == nil
      render :json => {:message => "club not found"}, :status => 404
      return
    end
  end

  def set_member
    puts @club
    if params[:email].present? && params[:phone_number].present?
      email = params[:email]
      phone_number = params[:phone_number]
      @member = @club.members.where(:email => email, :phone_number => phone_number).first
    else
      @member = nil
    end
    puts @member
    if @member == nil
      render :json => {:message => "member not found"}, :status => 404
      return
    end
  end
end