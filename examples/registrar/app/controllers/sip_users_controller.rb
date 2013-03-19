class SipUsersController < ApplicationController
  # GET /sip_users
  # GET /sip_users.json
  def index
    @sip_users = SipUser.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @sip_users }
    end
  end

  # GET /sip_users/1
  # GET /sip_users/1.json
  def show
    @sip_user = SipUser.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @sip_user }
    end
  end

  # GET /sip_users/new
  # GET /sip_users/new.json
  def new
    @sip_user = SipUser.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @sip_user }
    end
  end

  # GET /sip_users/1/edit
  def edit
    @sip_user = SipUser.find(params[:id])
  end

  # POST /sip_users
  # POST /sip_users.json
  def create
    @sip_user = SipUser.new(params[:sip_user])

    respond_to do |format|
      if @sip_user.save
        format.html { redirect_to @sip_user, notice: 'Sip user was successfully created.' }
        format.json { render json: @sip_user, status: :created, location: @sip_user }
      else
        format.html { render action: "new" }
        format.json { render json: @sip_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /sip_users/1
  # PUT /sip_users/1.json
  def update
    @sip_user = SipUser.find(params[:id])

    respond_to do |format|
      if @sip_user.update_attributes(params[:sip_user])
        format.html { redirect_to @sip_user, notice: 'Sip user was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @sip_user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sip_users/1
  # DELETE /sip_users/1.json
  def destroy
    @sip_user = SipUser.find(params[:id])
    @sip_user.destroy

    respond_to do |format|
      format.html { redirect_to sip_users_url }
      format.json { head :no_content }
    end
  end
end
