class ErrorsController < ActionController::Base
    respond_to :html, :json
    layout 'errors'

    def not_found
        if env["REQUEST_PATH"] =~ /^\/api/
            render json:  {error: "The Page You Were Looking For Was Not Found"}, :status => 404
        else
            @title = "404 The Page You Were Looking For Was Not Found"
            @message = "You may have mistyped the address or the page may have moved"
            render :show, :status => 404
        end
    end

    def exception
        if env["REQUEST_PATH"] =~ /^\/api/
            render json:  {error: "Oops Something Went Wrong"}, :status => 500
        else
            @title = "500 Oops Something Went Wrong"
            @message = ""
            render :show, :status => 500
        end
    end

    def non_processable
        if env["REQUEST_PATH"] =~ /^\/api/
            render json:  {error: "The Change You Wanted Was Rejected"}, :status => 422
        else
            @title = "422 The Change You Wanted Was Rejected"
            @message = "Maybe you tried to change something you didn't have access to"
            render :show, :status => 422
        end
    end
end