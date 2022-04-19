# ## Schema Information
#
# Table name: `members`
#
# ### Columns
#
# Name                    | Type               | Attributes
# ----------------------- | ------------------ | ---------------------------
# **`id`**                | `integer`          | `not null, primary key`
# **`name`**              | `string`           |
# **`email`**             | `string`           |
# **`club_id`**           | `integer`          |
# **`phone_number`**      | `string`           |
# **`full_time`**         | `boolean`          | `default(FALSE)`
# **`created_at`**        | `datetime`         | `not null`
# **`updated_at`**        | `datetime`         | `not null`
# **`qr_code_number`**    | `integer`          |
# **`league_rating`**     | `integer`          | `default(0)`
# **`usatt_number`**      | `integer`          |
# **`table_number`**      | `integer`          |
# **`membership_kind`**   | `string`           | `default("part_time")`
# **`notes`**             | `text`             |
# **`usatt_expiration`**  | `date`             |
#
# ### Indexes
#
# * `index_members_on_club_id`:
#     * **`club_id`**
#
# ### Foreign Keys
#
# * `fk_rails_...`:
#     * **`club_id => clubs.id`**
#

require 'test_helper'

class MemberTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
