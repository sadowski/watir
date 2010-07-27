# feature tests for automatic profile creation/deletion
# revision: $Revision: 1.0 $

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), '..') unless $SETUP_LOADED
require 'unittests/setup'

class TC_Profiles < Test::Unit::TestCase

  tag_method :fails_on_ie
  def test_list
      list = FireWatir::Profile.list
      assert(list.include?('default'))
  end
  
  tag_method :fails_on_ie
  def test_create
      FireWatir::Profile.create("profile_create_test")
      list = FireWatir::Profile.list
      assert(list.include?('profile_create_test'))
  end
  
  tag_method :fails_on_ie
  def test_delete
      list = FireWatir::Profile.list
      assert(list.include?('profile_create_test'))
      
      FireWatir::Profile.delete('profile_create_test')
      
      list = FireWatir::Profile.list
      assert_false(list.include?('profile_create_test'))
  end
  
  
  
end
