module DeviseSecurityExtension
  class OldPassword < ActiveRecord::Base
    self.table_name = 'old_passwords'

    belongs_to :password_archivable, polymorphic: true
  end
end