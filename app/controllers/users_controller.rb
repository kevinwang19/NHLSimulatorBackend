class UsersController < ApplicationController
    # POST /users
    def create
        @user = User.new(user_params)
        if @user.save
            render json: @user, status: :created
        else
            render json: { error: @user.errors }, status: :unprocessable_entity
        end
    end

    def user_params
        params.require(:user).permit(:username, :favTeamID)
    end
end