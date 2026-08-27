require 'test_helper'
require 'test_models'

class LimitableTest < ActiveSupport::TestCase
  test 'required_fields should contain the fields that Devise uses' do
    assert_same_content Devise::Models::SessionLimitable.required_fields(User), [:session_limitable_class,
                                                                                 :sessions_count_limit,
                                                                                 :sessions_expiration,
                                                                                 :sessions_reject_on_limit]
  end

  test 'should not raise exception' do
    assert_nothing_raised do
      create_user.log_limitable_request!
    end
  end

  test 'token should not be blank' do
    assert_not_empty create_user.log_limitable_request!
  end

  test 'should return token even on limit if sessions_reject_on_limit disabled' do
    swap Devise, sessions_reject_on_limit: false do
      user = create_user
      assert_not_empty user.log_limitable_request!

      assert_not_empty user.log_limitable_request!

      new_time = 5.seconds.from_now
      Time.stubs(:now).returns(new_time)
      assert_not_empty user.log_limitable_request!
    end
  end

  test 'should return false when on maximum session & reject session on limit' do
    timeout = 15.minutes
    swap Devise, sessions_expiration: timeout do
      user = create_user
      assert_not_empty user.log_limitable_request!

      assert_not user.log_limitable_request!

      new_time = (user.sessions_expiration + 2.seconds).from_now
      Time.stubs(:now).returns(new_time)
      assert_not_empty user.log_limitable_request!
    end
  end

  test 'reject third session when on limit' do
    swap Devise, sessions_count_limit: 2, sessions_expiration: 30.minutes do
      user = create_user
      assert_not_empty user.log_limitable_request!
      assert_not_empty user.log_limitable_request!

      assert_not user.log_limitable_request!
    end
  end

  test 'token should be accepted' do
    user = create_user
    token = user.log_limitable_request!
    assert user.accept_limitable_token?(token)
  end

  test 'use timeout_in if sessions_expiration not set' do
    timeout_in = 30.minutes
    swap Devise, timeout_in: timeout_in, sessions_expiration: nil do
      user = create_user
      assert user.sessions_expiration == timeout_in, <<-EOT
                timeout_in: #{timeout_in}
        sessions_expiration: #{user.sessions_expiration}
      EOT
    end
  end
end