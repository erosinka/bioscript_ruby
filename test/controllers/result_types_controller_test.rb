require 'test_helper'

class ResultTypesControllerTest < ActionController::TestCase
  setup do
    @result_type = result_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:result_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create result_type" do
    assert_difference('ResultType.count') do
      post :create, result_type: {  }
    end

    assert_redirected_to result_type_path(assigns(:result_type))
  end

  test "should show result_type" do
    get :show, id: @result_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @result_type
    assert_response :success
  end

  test "should update result_type" do
    patch :update, id: @result_type, result_type: {  }
    assert_redirected_to result_type_path(assigns(:result_type))
  end

  test "should destroy result_type" do
    assert_difference('ResultType.count', -1) do
      delete :destroy, id: @result_type
    end

    assert_redirected_to result_types_path
  end
end
