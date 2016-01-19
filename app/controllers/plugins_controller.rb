require 'json'
class PluginsController < ApplicationController
  before_action :set_plugin, only: [:build_form, :show, :edit, :update, :destroy]


#  def build_form
#  end


    def ordered
        respond_to do |format|
           format.html {redirect_to plugins_path}
           format.json { render json: @plugins_ordered} 
        end 
    end
def visual_index

end

  # GET /plugins
  # GET /plugins.json
  def index
    @plugins = (admin?) ? Plugin.all : Plugin.where(:deprecated => false)
#   @plugins.reject!{|e| e.deprecated == true} if !admin?

    @h_plugins = {}
    @h_plugin_infos = {}
    
    @plugins.each do |p|
      @h_plugins[p.id]=p
      @h_plugin_infos[p.id] = p.info_content
   end
   @sorted_plugin_ids = @h_plugin_infos.keys.sort{|a, b| @h_plugin_infos[a]['title'] <=> @h_plugin_infos[b]['title']}
    # @plugins_sorted_by_title = @h_plugin_infos.sort_by{|k, v| v[:title]}

    plugins_json = {}
    plugins_json[:plugins] = []
    @plugins.each do |p|
        # add desc_as_html, html_doc, html_src_code 
        line = {}
        line[:id] = p.key
        info = JSON.parse(p.info)
        line[:key] = info['title']
        line[:info] = info
        plugins_json[:plugins].push(line)
    end

    respond_to do |format|
      format.html
      format.json { render json: @plugins }
   #   format.json { render json: @plugins_ordered }
     # format.json { render json: plugins_json }
    end
  end

  # GET /plugins/1
  # GET /plugins/1.json
  def show
#      @plugin = Plugin.find(params[:id])
  end

  # GET /plugins/new
  def new
    @plugin = Plugin.new
  end

  # GET /plugins/1/edit
  def edit
  end

  # POST /plugins
  # POST /plugins.json
  def create
    @plugin = Plugin.new(plugin_params)

    respond_to do |format|
      if @plugin.save
       # format.js
        format.html { redirect_to @plugin, notice: 'Plugin was successfully created.' }
        format.json { render :show, status: :created, location: @plugin }
      else
        format.html { render :new }
        format.json { render json: @plugin.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /plugins/1
  # PATCH/PUT /plugins/1.json
  def update
    respond_to do |format|
      if @plugin.update(plugin_params)
        format.html { redirect_to @plugin, notice: 'Plugin was successfully updated.' }
        format.json { render :show, status: :ok, location: @plugin }
      else
        format.html { render :edit }
        format.json { render json: @plugin.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plugins/1
  # DELETE /plugins/1.json
  def destroy
    @plugin.destroy
    respond_to do |format|
      format.html { redirect_to plugins_url, notice: 'Plugin was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_plugin
        @plugin = Plugin.find(params[:id])  
        @info_content = @plugin.info_content
        @in_content = @info_content['in']
        @h_in = {}
        @in_content.map{ |i| @h_in[i['id']] = i}
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def plugin_params
      params[:plugin]
    end

end
