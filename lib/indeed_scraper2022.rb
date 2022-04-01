#!/usr/bin/env ruby

# file: indeed_scraper2022.rb

require 'ferrumwizard'
require 'nokorexi'
require 'yaml'

# Given the nature of changes to jobsearch websites,
# don't rely upon this gem working in the near future.



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

    url = @url_base
    url += 'start=' + start if start

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

    a2 = doc2.xpath  "//a[div/div/div/div/table/tbody/tr/td/div]"
    puts 'a2: ' + a2.length.inspect if @debug

    @a2 = a2.map {|x| Rexle.new x.to_s }

    @results = @a2.map do |doc|

      div = doc.element("a[@class='desktop']/div[@class='slider"  \
          "_container']/div[@class='slider_list']/div[@class='sl"  \
          "ider_item']/div[@class='job_seen_beacon']")
      td = div.element("table[@class='jobCard_mainContent']/tbo"  \
          "dy/tr/td[@class='resultContent']")

      # job title (e.g. Software Developer)
      jobtitle = td.element("div[@class='tapItem-gutter']/h2[@"  \
          "class='jobTitle-color-purple']/span")&.text
      puts 'jobtitle: ' + jobtitle.inspect if @debug

      salary = td.element("div[@class='metadataContainer']/"  \
          "div[@class='salary-snippet-container']/div[@class='sa"  \
          "lary-snippet']/span")&.text

      puts 'salary: ' + salary.inspect if @debug
      div1 = td.element("div[@class='companyInfo']")

      # company name (e.g. Coda Octopus Products Ltd)
      company_name = div1.element("span[@class='companyName']")&.text

      # company location (e.g. Edinburgh)
      location = div1.element("div[@class='companyLocation']")&.text
      tbody = div.element("table[@class='jobCardShelfContainer']/tbody")

      div3 = tbody.element("tr[@class='underShelfFooter']/td/di"  \
          "v[@class='result-footer']")

      # job (e.g. Our products are primarily written in C#, using...)
      jobsnippet = div3.xpath("div[@class='job-snippet']/ul/li/text()").join("\n")

      # visually (e.g. Posted 14 days ago)
      dateposted =  div3.element("span[@class='date']")&.texts
      date = (Date.today - dateposted.first.to_i).to_s if dateposted

      {
        link:  @url_base.sub(/\/[^\/]+$/,'') \
          + doc.root.attributes[:href].gsub(/&amp;/,'&'),
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
    e0 = doc.element("html/body/div/div/div/div/div/div/div/div")

    #div = e0.element("//div[@class='jobsearch-JobComponent']")
    div1 = e0.element("//div[@class='jobsearch-DesktopStickyContainer']")
    div2 = div1.element("div")

    # jobsearch (e.g. Full Stack Website Developer (Wordpress))
    jobtitle = div2.element("div[@class='jobsearch-JobInfoHead"  \
        "er-title-container']/h1[@class='jobsearch-JobInfoHead"  \
        "er-title']")&.text

    div3 = div2.element("div[@class='jobsearch-CompanyInfoCon"  \
        "tainer']/div[@class='jobsearch-CompanyInfoWithoutHead"  \
        "erImage']/div/div[@class='jobsearch-DesktopStickyCont"  \
        "ainer-subtitle']")

    # icl (e.g. Lyles Sutherland)
    cname = div3.xpath("div[@class='jobsearch-DesktopSt"  \
        "ickyContainer-companyrating']/div/div[@class='icl-u-x"  \
        "s-mr--xs']")[1]
    clink = div3.element('//a')
    company = cname.text ? cname.text : clink.text
    companylink = clink.attributes[:href] if clink

    salary = div1.element("//span[@class='attribute_snippet']")&.text
    type = div1.element("//span[@class='jobsearch-JobMetadataHeader-item']")&.texts&.last
    div5 = div3.xpath("div/div")
    location, worklocation = div5.map(&:text).compact

    # icl (e.g. Full-time, Permanent)
    jobtype = div1.element("div/div/div[@class='jobsearch-J"  \
        "obMetadataHeader-item']/span[@class='icl-u-xs-mt--xs']")
    jobtype = jobtype&.texts.join if jobtype

    # jobsearch (e.g. Urgently needed)
    jobnote1 = e0.element("//div[@class='jobsearch-DesktopTag"  \
        "']/div[@class='urgently-hiring']/div[@class='jobsearc"  \
        "h-DesktopTag-text']")&.text

    # jobsearch (e.g. 10 days ago)
    days = e0.element("//div[@class='jobsearch-JobTab-con"  \
        "tent']/div[@class='jobsearch-JobMetadataFooter']/div[2]")&.text
    d = Date.today - days.to_i
    datepost = d.strftime("%Y-%m-%d")


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

  def archive(filepath='/tmp/indeed')

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
      links = RXFReader.reveal(item[:link])
      puts 'links: ' + links.inspect

      url = links.last
      id = url[/(?<=\?jk=)[^&]+/]

      if index[id.to_sym] then
        next
      else

        File.write File.join(filepath, 'j' + id + '.txt'), page(i+1)

        h = {
          link: url[/^[^&]+/],
          title: item[:title].to_s,
          salary: item[:salary].to_s,
          company: item[:company].to_s.strip,
          location: item[:location].to_s,
          jobsnippet: item[:jobsnippet],
          date: item[:date]
        }

        index[id.to_sym] = h
      end

    end

    File.write idxfile, index.to_yaml

  end

  def list()

    @results.map.with_index do |x,i|
      "%2d. %s" % [i+1,x[:title]]
    end.join("\n")

  end


end
