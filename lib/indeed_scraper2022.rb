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

  def page()
  end

  # used for debugging
  #
  def a2()
    @a2
  end

  private

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
          "class='jobTitle-color-purple']/span").text
      puts 'jobtitle: ' + jobtitle.inspect if @debug

      salary = td.element("div[@class='metadataContainer']/"  \
          "div[@class='salary-snippet-container']/div[@class='sa"  \
          "lary-snippet']/span")
      salary = salary.text if salary
      puts 'salary: ' + salary.inspect if @debug
      div1 = td.element("div[@class='companyInfo']")

      # company name (e.g. Coda Octopus Products Ltd)
      company_name = div1.element("span[@class='companyName']").text

      # company location (e.g. Edinburgh)
      location = div1.element("div[@class='companyLocation']").text
      tbody = div.element("table[@class='jobCardShelfContainer']/tbody")

      div3 = tbody.element("tr[@class='underShelfFooter']/td/di"  \
          "v[@class='result-footer']")

      # job (e.g. Our products are primarily written in C#, using...)
      jobsnippet = div3.element("div[@class='job-snippet']/ul/li").text

      # visually (e.g. Posted 14 days ago)
      dateposted =  div3.element("span[@class='date']").texts
      date = (Date.today - dateposted.first.to_i).to_s

      {
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
