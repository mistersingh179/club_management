require 'csv'

class MembersController < AuthenticatedController

  before_action :set_club, except: [:global_search]
  before_action :set_member, only: [:show, :update, :destroy]

  def global_search
    if params[:email].blank? && params[:phone_number].blank?
      render json: {
        :success => false,
        :qr_code_number => '',
        :club_keyword => ''
      }
      return
    end

    @member1 = Member.find_by(:email => params[:email])
    @member2 = Member.find_by(:phone_number => params[:phone_number])
    @member = @member1 || @member2 
    
    if @member.present? && @member.qr_code_number.present?
      render json: {
        :success => true,
        :qr_code_number => @member.qr_code_number,
        :club_keyword => @member.club.keyword
      }
    else 
      render json: {
        :success => false,
        :qr_code_number => '',
        :club_keyword => ''
      }
    end
  end

  def parse_ratings_csv_file
    # Ensure file is uploaded
    if params[:file].present?
      file = params[:file]

      # Parse the uploaded CSV file
      csv = ::CSV.parse(file.read, headers: true).reject { |row| row.all?(&:nil?) }.map(&:to_hash)

      # Transform the CSV into the hash format required for updating the members
      csv = csv.each_with_object({}) do |h, obj|
        key = h["FirstName"] + " " + h["LastName"]

        # Ensure default values are present if fields are blank
        h["LeagueRating"] = '0' if h["LeagueRating"].blank?
        h["Expiration"] = '01/01/1990' if h["Expiration"].blank?
        h["MemberID"] = '0' if h["MemberID"].blank?

        # Prepare the value in the format "LeagueRating|Expiration|MemberID"
        value = h["LeagueRating"] + "|" + h["Expiration"] + "|" + h["MemberID"]
        obj[key.downcase] = value
      end

      # Existing logic to update member information from the hash
      @club.members.each do |member|
        if csv[member.name.downcase].present?
          # Split the string to extract rating, expiration, and member ID
          rating, expiration, usatt_number = csv[member.name.downcase].split("|")

          # Convert values where necessary
          rating = rating.to_i
          expiration = Date.strptime(expiration, '%m/%d/%Y')
          usatt_number = usatt_number.to_i

          # Update member record
          member.update_column :league_rating, rating
          member.update_column :usatt_expiration, expiration
          member.update_column :usatt_number, usatt_number
        end
      end

      # Return updated members as JSON response
      render json: @club.members
    else
      # Handle missing file
      render json: { error: "No file uploaded" }, status: :unprocessable_entity
    end
  end


  def update_ratings
    # client = SimplyCompeteWrapper.new 'gallian83@hotmail.com', 'bttc', 1017
    client = SimplyCompeteWrapper.new @club.simply_compete_username,
      @club.simply_compete_password, 
      @club.simply_compete_league_id
    
    client.setup_session
    hash = client.download_csv
    hash = hash.transform_keys { |k| k.downcase }

    @club.members.each do |member|
      if hash[member.name.downcase].present?
        rating = hash[member.name.downcase].split("|")[0]
        if rating.present?
            rating = rating.to_i
        else
            rating = 0
        end

        expiration = hash[member.name.downcase].split("|")[1]
        expiration = Date.strptime(expiration, '%m/%d/%Y')

        usatt_number = hash[member.name.downcase].split("|")[2]
        if usatt_number.present?
            usatt_number = usatt_number.to_i
        else
            usatt_number = 0
        end


        member.update_column :league_rating, rating
        member.update_column :usatt_expiration, expiration
        member.update_column :usatt_number, usatt_number
      end
    end
    render json: @club.members
  end

  # GET /members
  def index
    @members = @club.members.all

    render json: @members.to_json(
      :include => {
        :checkins => {
          :include => {
            :member => {
              :only => :id
            }
          }
        }
      }
    )
  end

  def checked_in_today
    @members = @owner.members.joins(:checkins).
      where("checkins.created_at > ? and checkins.created_at < ?",
            Time.current.beginning_of_day, Time.current.end_of_day)

    render json: @members.to_json(
      :include => {
        :checkins => {
          :include => {
            :member => {
              :only => :id
            }
          }
        }
      }
    )
  end

  def checked_in_on_date
    @date = Time.zone.strptime params[:date], '%m-%d-%Y'

    @members = @owner.members.joins(:checkins).
      where("checkins.created_at > ? and checkins.created_at < ?",
            @date.beginning_of_day, @date.end_of_day)

    render json: @members.to_json(
      :include => {
        :checkins => {
          :include => {
            :member => {
              :only => :id
            }
          }
        }
      }
    )
  end

  # GET /members/1
  def show
    render json: @member
  end

  def lookup
    logger.info "will lookup member which matches these params: #{lookup_params[:lookup_params]}"
    @member = @club.members.find_by(lookup_params)

    return render :status => :not_found if @member.blank?

    logger.info "member found: #{@member}"

    render json: @member.to_json(
      :include => {
        :checkins => {
          :include => {
            :member => {
              :only => :id
            }
          }
        }
      }
    )
  end

  def mark_all_part_time
    @club.members.update_all :membership_kind => 'part_time'
  end

  # POST /members
  def create
    @member = @club.members.new(member_params)

    if @member.save
      render json: @member.to_json(
        :include => {
          :club => {
            :include => {
              :members => {
                :only => :id
              }
            },
            :only => :id
          }
        }
      ), status: :created
    else
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /members/1
  def update
    if @member.update(member_params)
      render json: @member
    else
      puts "got error while updating member"
      puts @member.errors.to_json
      render json: @member.errors, status: :unprocessable_entity
    end
  end

  # DELETE /members/1
  def destroy
    @member.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_club
      @club = @owner.clubs.find(params[:club_id])
      end

    def set_member
      @member = @club.members.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def member_params
      params.require(:member).permit(:name, :email, :club_id, :phone_number,
                                     :qr_code_number, :league_rating, :notes,
                                     :usatt_number, :table_number, :membership_kind)
    end

    def lookup_params
      params.require(:lookup_params).permit(:qr_code_number, :email, :phone_number)
    end
end
