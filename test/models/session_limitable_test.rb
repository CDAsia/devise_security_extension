require 'test_helper'
require 'test_models'

class LimitableTest < ActiveSupport::TestCase
  test 'required_fields should contain the fields that Devise uses' do
    assert_same_content Devise::Models::SessionLimitable.required_fields(User), [:session_limitable_class,
                                                                                 :sessions_count_limit,
                                                                                 :timeout_session_in,
                                                                                 :reject_session_on_limit]
  end

  test 'should not raise exception' do
    assert_nothing_raised do
      create_user.log_limitable_request!
    end
  end

  test 'token should not be blank' do
    assert_not_empty create_user.log_limitable_request!
  end

  test 'should return token even on limit if reject_session_on_limit disabled' do
    swap Devise, reject_session_on_limit: false do
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
    swap Devise, timeout_session_in: timeout do
      user = create_user
      assert_not_empty user.log_limitable_request!

      assert_not user.log_limitable_request!

      new_time = (user.timeout_session_in + 2.seconds).from_now
      Time.stubs(:now).returns(new_time)
      assert_not_empty user.log_limitable_request!
    end
  end

  test 'reject third session when on limit' do
    swap Devise, sessions_count_limit: 2, timeout_session_in: 30.minutes do
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

  test 'use timeout_in if timeout_session_in not set' do
    timeout_in = 30.minutes
    swap Devise, timeout_in: timeout_in, timeout_session_in: nil do
      user = create_user
      assert user.timeout_session_in == timeout_in, <<-EOT
                timeout_in: #{timeout_in}
        timeout_session_in: #{user.timeout_session_in}
      EOT
    end
  end
end