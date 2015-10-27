require 'test_helper'

class ParamTypesControllerTest < ActionController::TestCase
  setup do
    @param_type = param_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:param_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create param_type" do
    assert_difference('ParamType.count') do
      post :create, param_type: {  }
    end

    assert_redirected_to param_type_path(assigns(:param_type))
  end

  test "should show param_type" do
    get :show, id: @param_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @param_type
    assert_response :success
  end

  test "should update param_type" do
    patch :update, id: @param_type, param_type: {  }
    assert_redirected_to param_type_path(assigns(:param_type))
  end

  test "should destroy param_type" do
    assert_difference('ParamType.count', -1) do
      delete :destroy, id: @param_type
    end

    assert_redirected_to param_types_path
  end
end
