# ## Schema Information
#
# Table name: `checkins`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`member_id`**         | `integer`          |
# **`created_at`**        | `datetime`         | `not null`
# **`updated_at`**        | `datetime`         | `not null`
# **`paid`**              | `boolean`          | `default(FALSE)`
# **`amount_collected`**  | `integer`          | `default(0)`
#
# ### Indexes
#
# * `index_checkins_on_member_id`:
#     * **`member_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`member_id => members.id`**
#

class Checkin < ApplicationRecord
  belongs_to :member

  scope :of_today, -> { where("checkins.created_at >= ? and checkins.created_at <= ?",
                              Time.current.beginning_of_day, Time.current.end_of_day) }

  before_create :set_paid

  after_create :set_table_number

  private

  def set_paid
    if member.membership_kind == "full_time" || member.membership_kind == "complimentary"
      self.paid = false
    end
  end

  def set_table_number
    self.member.update :table_number => 0
  end

end
