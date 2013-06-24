class SitesController < ApplicationController  

  require 'fileutils'
  require 'open-uri'

  # GET /posts
  def index
    @sites = Site.all
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /posts/1
  def show
    @site = Site.find(params[:id])

    @url_without_http = @site.url
    if @site.url[0..6] == "http://"
      @url_without_http = @site.url[7..-1]
    end
    @url_with_http = @site.url
    if @site.url[0..6] != "http://"
      @url_with_http = "http://" + @url_with_http
    end

    respond_to do |format|
      format.html 
    end
  end

  def show_fail

  end

  def show_html
    site_list = Site.where(:hash_name => params[:hash_name])
    if site_list.length > 0
      site = site_list.first  
    else
      return render "error.html.erb"
    end

    @html = site.html

  end

  def show_all
    @sites = Site.all
  end

  # GET /posts/new
  def new
    respond_to do |format|
      format.html # new.html.erb
    end
  end 
   
  def archive_instructions
    respond_to do |format|
      format.html # archive_instructions.html.erb
    end
  end    

  def generate_lowercase_hash
    (0...8).map{97.+(rand(26)).chr}.join
  end

  # POST /posts
  def create
    @site = Site.new(params[:site])
    temp_hash_name = generate_lowercase_hash
    site_list = Site.where(:hash_name => temp_hash_name)

    while site_list.length > 0
      temp_hash_name = generate_lowercase_hash
      site_list = Site.where(:hash_name => temp_hash_name)
    end    
    @site.hash_name = temp_hash_name

    path = Rails.root.join('public').join(@site.hash_name)
    url = @site.url

    if not system("wget -pk -P #{path} #{url}")
      return redirect_to show_fail_path(:url => @site.url)
    end

    if @site.save
      UserMailer.archive_confirmation(@site).deliver

      @url_with_http = @site.url
      if @site.url[0..6] != "http://"
        @url_with_http = "http://" + @url_with_http
      end
      Net::HTTP.get(URI(@url_with_http)) =~ /<title>(.*?)<\/title>/
      @title = $1

      redirect_to @site, notice: 'Your site archive request was successful.' 
    else
      render action: "new" 
    end
  end

  def cache
    @site = Site.where(:hash_name => params[:hash_name]).first # should be unique

    @url_without_http = @site.url
    if @site.url[0..6] == "http://"
      @url_without_http = @site.url[7..-1]
    end
    @url_with_http = @site.url
    if @site.url[0..6] != "http://"
      @url_with_http = "http://" + @url_with_http
    end

    render :layout => false
  end

  # DELETE /posts/1
  def destroy
    @site = Site.find(params[:id])
    @site.destroy

    #redirect_to sites_url 
    redirect_to show_all_path
    
  end

  def download_test
    system("zip -j #{Rails.root}/public/images/railspic #{Rails.root}/public/images/rails.png")
    send_file("#{Rails.root}/public/images/railspic.zip")
    system("rm #{Rails.root}/public/images/railspic.zip")
  end

  def get_wget_filename(url)
    url_copy = url
    url = url[%r{.*//(.*)}, 1]
    if not url
      url = url_copy
    end
    if url[-1] == "/"
      url = url[0..-2]
    end
    filename = url[%r{.*/(.*)}, 1]
    if not filename
      filename = "index.html"
    end
    return filename    
  end

  def download
    hash_name = generate_lowercase_hash
    url_input = params[:url]
    name = params[:name]
    author = params[:author]
    title = params[:title]
    year = params[:year]
    different_domain = params[:different_domain]
    recursive = params[:recursive]

    if not name =~ /\A[A-Za-z0-9]+\z/ or name.length > 20
      @notice = "Tag must contain only alphanumeric characters, and can't be empty"
      return render :action => :new 
    end

    #if not url =~ /\A\S+\z/
    #  @notice = "URL must not contain whitespace"
    #  return render action: "new" 
    #end

    url_array = url_input.strip.split(/\s+/)
    url_array.each { |url|
      begin
        open(url) 
      rescue
        @notice = "We cannot open your URL: #{url}"
        return render action: "new"  
      end
      #begin
      #  url_parsed = URI.parse(url)
      #  response = Net::HTTP.get_response(url_parsed)
      #  if response.code[0] == '4' or response.code[0] == '5'
      #    @notice = "URL #{url} does not return a valid response"
      #    return render action: "new" 
      #  end
      #rescue URI::InvalidURIError
      #  @notice = "Invalid URL #{url}" 
      #  return render action: "new" 
      #rescue SocketError
      #  @notice = "URL #{url} does not exist"
      #  return render action: "new" 
      #rescue 
      #  @notice = "Your URL #{url} is not good enough"
      #  return render action: "new"        
      #end
    }

    url_join_comma = url_array.join(", ")
    wget_filename_join_comma = url_array.map { |url| "\\url\{#{name}/#{get_wget_filename(url)}\}" } .join(", ")

    download_path = Rails.root.join('public').join('downloads')
    base_path = download_path.join(hash_name)
    zip_path = base_path.join(name)
    files_path = zip_path.join('files')

    if not ['1','2','3'].include? recursive
      recursive = false
    end

    @notice = "We cannot download your URL(s): #{url_array}."

    if different_domain
      if recursive
        if not system("wget", "-Q20m", "-pkH", "-r", "--level=#{recursive}", "-nd", "-P", "#{files_path}", *url_array)
          FileUtils.remove_dir base_path, true
          return render action: "new"  
        end
      else
        if not system("wget", "-Q20m", "-pkH", "-nd", "-P", "#{files_path}", *url_array)
          FileUtils.remove_dir base_path, true
          return render action: "new"  
        end
      end
    else
      if recursive
        if not system("wget", "-Q20m", "-pk", "-r", "--level=#{recursive}", "-nd", "-P", "#{files_path}", *url_array)
          FileUtils.remove_dir base_path, true
          return render action: "new"  
        end
      else
        if not system("wget", "-Q20m", "-pk", "-nd", "-P", "#{files_path}", *url_array)
          FileUtils.remove_dir base_path, true
          return render action: "new"  
        end
      end
    end

    #if not system("/bin/wget", "-pk", "-nd", "-P", "#{files_path}", "#{url}")
    #  return redirect_to show_fail_path(:url => url)
    #end

    File.open("#{zip_path}/#{name}.bib", 'w') { |file|
      file_str = "@webpage{#{name},\n"
      file_str += "  url = {#{url_join_comma}},\n"
      file_str += "  author = {#{author}},\n"
      file_str += "  title = {#{title}},\n"
      file_str += "  year = {#{year}},\n"
      file_str += "  lastchecked = {#{Time.new.strftime("%Y-%m-%d")}},\n"
      file_str += "  note = {Cached at #{wget_filename_join_comma}},\n"
      file_str += "}\n"
      file.write(file_str)
    }

    url_link = url_array.collect { |url| "<a href=\"#{url}\" style=\"font-size:12px;font-family:'Times New Roman';color:#000080\">#{url}</a>" }.join (', ')

    preamble = "<!DOCTYPE html><div style=\"background:#fff;border:1px solid #999;margin:-1px -1px 0;\"><div style=\"background:#F6CEE3;border:1px solid #999;color:#000;margin:12px;padding:8px;text-align:left;font-size: 12px;font-family:'Times New Roman', Times, serif\"> This is a cache of the website #{url_link}, made by <a href='http://bibsnag.csail.mit.edu' style=\"font-size:12px;font-family:'Times New Roman';color:#000080\">BibSnag</a> at #{Time.new.utc}. </div></div> <div style=\"position:relative\">"

    Dir.glob("#{files_path}/*.html*") do |file| 
      new_file = file + ".new"
      File.open("#{new_file}", 'w') do |fo|
        fo.puts preamble
        File.foreach("#{file}") do |li|
          fo.puts li        
        end
      end
      File.delete("#{file}")
      File.rename("#{new_file}", "#{file}")

    end

    system("cd #{base_path} && zip -r #{name} #{name}")
    
    send_file("#{zip_path}.zip")
    FileUtils.remove_dir base_path, true
    #system("rm -rf #{base_path}")
    #redirect_to show_all_path
  end


end
