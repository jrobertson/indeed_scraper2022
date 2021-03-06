#!/usr/bin/env ruby

# file: indeed_scraper2022.rb

require 'ferrumwizard'
require 'nokorexi'
require 'yaml'
require 'reveal_url22'

# Given the nature of changes to jobsearch websites,
# don't rely upon this gem working in the near future.



# this gem consists of 3 main classes:
#
# *  IndeedScraper2022 - Scrapes a page of vacancies from indeed.com
# *  IS22Plus - Archives the scraped vacancies to local file
# *  IS22Archive - Allows viewing of archived vacancies offline
#

class IndeedScraper2022Err < Exception
end

class IndeedScraper2022

  attr_reader :browser

  def initialize(url='https://uk.indeed.com/?r=us', q: '', location: '',
                 headless: true, cookies: nil, debug: false)

    @debug = debug
    @url_base, @q, @location = url, q, location
    @headless, @cookies = headless, cookies

    fw = FerrumWizard.new( headless: @headless, cookies: @cookies, debug: @debug)
    @browser = fw.browser

  end

  # returns an array containing the job search result
  #
  def results()
    @results
  end

  def search(q: @q, location: @location, start: nil)
    puts 'inside search' if @debug
    url = @url_base
    url += 'start=' + start if start
    puts 'url: ' + url.inspect if @debug

    @browser.goto(url)
    #@browser.network.wait_for_idle
    puts 'sleeping for 4 seconds' if @debug
    sleep 4

    if q.length > 1 then

      input = @browser.at_xpath("//input[@name='q']")

      # select any existing text and overwrite it
      input.focus.type(:home); sleep 0.2
      input.focus.type(:shift, :end); sleep 0.2
      input.focus.type(q); sleep 0.2
    end

    if location.length > 1 then

      input2 = @browser.at_xpath("//input[@name='l']")

      # select any existing text and overwrite it
      input2.focus.type(:home); sleep 0.2
      input2.focus.type(:shift, :end); sleep 0.2
      input2.focus.type(location); sleep 0.2

    end

    button = @browser.at_xpath("//button[@type='submit']")
    button.click
    #@browser.network.wait_for_idle
    puts 'sleeping for 2 seconds' if @debug
    sleep 2

    doc2 = Nokogiri::XML(@browser.body)
    File.write '/tmp/body.txt', doc2.to_s if @debug

    a2 = doc2.root.xpath  "//li/div[div/div/div/div/table/tbody/tr/td/div/h2/a]"
    puts 'a2: ' + a2.length.inspect if @debug

    @a2 = a2.map {|x| Rexle.new x.to_s }

    @results = @a2.map do |doc|

      div = doc.element("div[@class='cardOutline']/div[@class='slider"  \
          "_container']/div[@class='slider_list']/div[@class='sl"  \
          "ider_item']/div[@class='job_seen_beacon']")

      td = div.element("table[@class='jobCard_mainContent']/tbo"  \
          "dy/tr/td[@class='resultContent']")

      # job title (e.g. Software Developer)
      job = td.element("div[@class='tapItem-gutter']/h2[@"  \
          "class='jobTitle-color-purple']/a")
      href = job.attributes[:href]
      jobtitle = job.element("span")&.text

      puts 'jobtitle: ' + jobtitle.inspect if @debug

      sal = td.element("div[@class='metadataContainer']/"  \
          "div[@class='salary-snippet-container']")

      salary = if sal then
        sal_e = sal.element("div[@class='attribute_snippet']")
        if sal_e then
          sal_e.texts[0]
        else
          sal_e2 = sal.element("div[@class='salary-snippet']/span")
          sal_e2 ? sal_e2.text : ''
        end
      else
        ''
      end

      puts 'salary: ' + salary.inspect if @debug
      div1 = td.element("div[@class='companyInfo']")

      # company name (e.g. Coda Octopus Products Ltd)
      coname = div1.element("span[@class='companyName']")
      puts 'coname: ' + coname.text.inspect if @debug
      company_name = coname.text.to_s.strip.length > 1 ? coname.text : coname.element('a').text

      # company location (e.g. Edinburgh)
      location = div1.element("div[@class='companyLocation']")&.text
      tbody = div.element("table[@class='jobCardShelfContainer']/tbody")

      div3 = tbody.element("tr[@class='underShelfFooter']/td/di"  \
          "v[@class='result-footer']")

      # job (e.g. Our products are primarily written in C#, using...)
      advert_items = div3.xpath("div[@class='job-snippet']/ul/li/text()")
      jobsnippet = if advert_items.any? then
        advert_items.join("\n")
      else
        div3.element("div[@class='job-snippet']").text
      end

      # visually (e.g. Posted 14 days ago)
      dateposted =  div3.element("span[@class='date']")&.texts
      date = (Date.today - dateposted.first.to_i).to_s if dateposted

      {
        link:  @url_base.sub(/\/[^\/]+$/,'') \
          + href.gsub(/&amp;/,'&'),
        title: jobtitle,
        salary: salary,
        company: company_name,
        location: location,
        jobsnippet: jobsnippet,
        date: date
      }

    end
  end

  def page(n)

    if n < 1 or n > @results.length then
      raise IndeedScraper2022Err, 'Invalid page no.'
    end

    url = @results[n-1][:link]
    fetchjob(url)
  end

  private

  def fetchjob(url)

    doc = Nokorexi.new(url).to_doc
    puts 'before e0' if @debug
    e0 = doc.element("html/body/div/div/div/div/div/div/div/div")

    #div = e0.element("//div[@class='jobsearch-JobComponent']")
    puts 'before div1' if @debug
    div1 = e0.element("//div[@class='jobsearch-DesktopStickyContainer']")
    puts 'before div2' if @debug
    div2 = div1.element("div")

    # jobsearch (e.g. Full Stack Website Developer (Wordpress))
    puts 'before jobtitle' if @debug
    jobtitle = div2.element("div[@class='jobsearch-JobInfoHead"  \
        "er-title-container']/h1[@class='jobsearch-JobInfoHead"  \
        "er-title']")&.text

    puts 'before div3' if @debug
    div3 = div2.element("div[@class='jobsearch-CompanyInfoCon"  \
        "tainer']/div[@class='jobsearch-CompanyInfoWithoutHead"  \
        "erImage']/div/div[@class='jobsearch-DesktopStickyCont"  \
        "ainer-subtitle']")

    # icl (e.g. Lyles Sutherland)
    puts 'before cname' if @debug
    cname = div3.xpath("div[@class='jobsearch-DesktopSt"  \
        "ickyContainer-companyrating']/div/div[@class='icl-u-x"  \
        "s-mr--xs']")[1]
    puts 'before clink' if @debug
    clink = div3.element('//a')
    company = cname.text ? cname.text : clink.text
    companylink = clink.attributes[:href] if clink

    puts 'before salary' if @debug
    salary = div1.element("//span[@class='attribute_snippet']")&.text
    puts 'before type' if @debug
    type = div1.element("//span[@class='jobsearch-JobMetadataHeader-item']")&.texts&.last
    div5 = div3.xpath("div/div")
    location, worklocation = div5.map(&:text).compact

    # icl (e.g. Full-time, Permanent)
    puts 'before jobtype' if @debug
    jobtype = div1.element("div/div/div[@class='jobsearch-J"  \
        "obMetadataHeader-item']/span[@class='icl-u-xs-mt--xs']")
    jobtype = jobtype&.texts.join if jobtype

    # jobsearch (e.g. Urgently needed)
    puts 'before jobnote1' if @debug
    jobnote1 = e0.element("//div[@class='jobsearch-DesktopTag"  \
        "']/div[@class='urgently-hiring']/div[@class='jobsearc"  \
        "h-DesktopTag-text']")&.text

    # jobsearch (e.g. 10 days ago)
    puts 'before days' if @debug
    days = e0.element("//div[@class='jobsearch-JobTab-con"  \
        "tent']/div[@class='jobsearch-JobMetadataFooter']/div[2]")&.text
    d = Date.today - days.to_i
    datepost = d.strftime("%Y-%m-%d")


    puts 'before jobdesc' if @debug
    jobdesc = e0.element("//div[@class='icl-u-xs-mt--md']/div[@cl"  \
        "ass='jobsearch-jobDescriptionText']").xml

    {
      title: jobtitle,
      type: type,
      company: company,
      companylink: companylink,
      location: location,
      salary: salary,
      worklocation: worklocation,
      note: jobnote1,
      date: datepost,
      desc: jobdesc
    }

  end


end

class IS22Plus < IndeedScraper2022

  def initialize(q: '', location: '', headless: true, cookies: nil, debug: false)
    super(q: q, location: location, headless: headless, cookies: cookies,
          debug: debug)
  end

  # note: The most efficient method to accumulate vacancy articles is to
  #       execute archive() daily
  #
  def archive(filepath='/tmp/indeed')

    search() if @results.nil?

    return unless @results

    FileUtils.mkdir_p filepath

    idxfile = File.join(filepath, 'index.yml')

    index = if File.exists? idxfile then
      YAML.load(File.read(idxfile))
    else
      {}
    end

    @results.each.with_index do |item, i|

      puts 'saving ' + item[:title] if @debug
      puts 'link: ' + item[:link].inspect
      url = URL.reveal(item[:link])
      item[:link] = url
      puts 'url: ' + url.inspect if @debug
      id = url[/(?<=jk=)[^&]+/]

      if index[id.to_sym] then

        # the vacancy record has previously been saved
        #
        next

      else

        # write the full page vacancy article to file
        #
        File.write File.join(filepath, 'j' + id + '.txt'), page(i+1)

        h = {
          link: url[/^[^&]+/],
          title: item[:title].to_s,
          salary: item[:salary].to_s,
          company: item[:company].to_s.strip,
          location: item[:location].to_s,
          jobsnippet: item[:jobsnippet].to_s,
          date: item[:date],
          added: Time.now.strftime("%Y-%m-%d")
        }

        # add the vacancy snippet to the index file
        #
        index[id.to_sym] = h
      end

    end

    # save the vacancy index file
    #
    File.write idxfile, index.to_yaml

  end

  def list()

    @results.map.with_index do |x,i|
      "%2d. %s" % [i+1,x[:title]]
    end.join("\n")

  end


end


class IS22Archive
  include RXFReadWriteModule

  attr_reader :index

  def initialize(filepath='/tmp/indeed', debug: false)

    FileX.mkdir_p filepath
    @idxfile = File.join(filepath, 'index.yml')

    @index = if FileX.exists? @idxfile then
      YAML.load(FileX.read(@idxfile))
    else
      {}
    end

  end

  def list()

    @index.to_a.reverse.map.with_index do |x,i|

      id, h = x

      puts 'h: ' + h.inspect if @debug
      co = h[:company].length > 1 ? " (%s)" % h[:company] : ''
      "%2d. %s: %s%s" % [i+1, Date.parse(h[:added]).strftime("%d %b"), h[:title], co]

    end.join("\n")

  end

  def to_html()

    rows = latest().map do |h|

      puts 'h: ' + h.inspect if @debug
      co = h[:company].length > 1 ? " (%s)" % h[:company] : ''
      "* %s: [%s](%s)%s" % [h[:added].strftime("%d %b"), h[:title], h[:link], co]

    end.join("\n")


    md = '# Indeed.com: Latest jobs

' + rows

    RDiscount.new(md).to_html

  end

  def to_form(action: '')

    rows = latest().map.with_index do |h, i|

      co = h[:company].length > 1 ? " (%s)" % h[:company] : ''

      "<input type='checkbox' id='#{h[:jobid]}' name='#{h[:jobid]}' value='#{h[:title]}'/>
      <label for='j#{i}'>#{h[:added].strftime("%d %b")}: #{h[:title] + ' ' + co}</label><br/>
      "

    end.join("\n")


    return "<form action='#{action}'>#{rows}" +
        "<input type='submit' value='submit'/></form>"

  end

  def filter(a)

    dx = Dynarex.new
    a2 = latest().select {|h| a.include? h[:jobid] }
    dx.import a2

    return dx
  end

  private

  def latest()

    a = @index.to_a.map do |id, h|
      h[:jobid] = id
      h[:added] = Date.parse(h[:added]) if h[:added].is_a? String
      h
    end

    a.select do |x|
      x[:added] >= (Date.today - 7)
    end.reverse

  end

end

