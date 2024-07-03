class UsersController < ApplicationController
    # POST /users
    def create
        @user = User.new(user_params)
        if @user.save
            render json: user, status: :created
        else
            render json: user.errors, status: :unprocessable_entity
        end
    end

    def user_params
        params.require(:user).permit(:username, :favTeamID)
    end

    # GET /users
    def index
        @users = User.all
        render json: @users
    end

    # GET /users/:user_id
    def show
        @user = User.find_by(userID: params[:user_id])
        if @user
            render json: @user
        else
            render json: { error: "User not found" }, status: :not_found
        end
    end
end