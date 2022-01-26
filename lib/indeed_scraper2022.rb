#!/usr/bin/env ruby

# file: indeed_scraper2022.rb

require 'mechanize'
require 'nokorexi'

# Given the nature of changes to jobsearch websites,
# don't rely upon this gem working in the near future.


class IndeedScraper2022

  def initialize(url='https://uk.indeed.com/?r=us', q: '', location: '', debug: false)

    @debug = debug
    @url_base, @q, @location = url, q, location
    @results = search

  end

  # returns an array containing the job search result
  #
  def results()
    @results
  end

  def page(n)
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
    company = cname ? cname.text : clink.text
    companylink = clink.attributes[:href] if clink

    div5 = div3.xpath("div/div")
    location, worklocation = div5.map(&:text).compact

    # icl (e.g. Full-time, Permanent)
    jobtype = div1.element("div/div/div[@class='jobsearch-J"  \
        "obMetadataHeader-item']/span[@class='icl-u-xs-mt--xs']")
    jobtype = jobtype.texts.join if jobtype

    # jobsearch (e.g. Urgently needed)
    jobnote1 = e0.element("//div[@class='jobsearch-DesktopTag"  \
        "']/div[@class='urgently-hiring']/div[@class='jobsearc"  \
        "h-DesktopTag-text']")&.text

    # jobsearch (e.g. 10 days ago)
    datepost = e0.element("//div[@class='jobsearch-JobTab-con"  \
        "tent']/div[@class='jobsearch-JobMetadataFooter']/div")&.text

    jobdesc = e0.element("//div[@class='icl-u-xs-mt--md']/div[@cl"  \
        "ass='jobsearch-jobDescriptionText']").xml

    {
      title: jobtitle,
      company: company,
      companylink: companylink,
      location: location,
      worklocation: worklocation,
      note: jobnote1,
      date: (Date.today - datepost.to_i).to_s,
      desc: jobdesc
    }

  end

  def search(q='', location='')

    a = Mechanize.new

    page = a.get(@url_base)
    form = page.forms.first
    form.fields[0].value = @q
    form.fields[1].value = @location
    pg = form.submit

    doc2 = Nokogiri::XML(pg.body)

    a2 = doc2.xpath  "//a[div/div/div/div/table/tbody/tr/td/div]"
    puts 'a2: ' + a2.length.inspect if @debug

    @a2 = a2.map {|x| Rexle.new x.to_s }

    @a2.map do |doc|

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
      dateposted =  div3.element("span[@class='date']").texts
      date = (Date.today - dateposted.first.to_i).to_s

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
end

class IS22Plus < IndeedScraper2022

  def initialize(q: '', location: '', debug: false)
    super(q: q, location: location, debug: debug)
  end

  def list()

    @results.map.with_index do |x,i|
      "%2d. %s" % [i,x[:title]]
    end.join("\n")

  end

end
