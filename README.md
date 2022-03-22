# Introducing the Indeed_Scraper2022 gem

    require 'indeed_scraper2022'

    filter = ' -junior -apprentice -intern'
    is22 = IS22Plus.new(q: 'developer' + filter, location: 'edinburgh', debug: true)

    results = is22.results
    results.length #=> 15

    results[0]

<pre>
{:link=&gt;                                             
  "https://uk.indeed.com/pagead/clk?mo=r&ad=-6NYlbfkN0AgNtDiIcm6wu_HH0I_6hlBGfb1bkC...",
 :title=&gt;"Front End Developer",                      
 :salary=&gt;"From &#xA3;30,000 a year",                
 :company=&gt;"lamontdesign",                           
 :location=&gt;"Edinburgh",                             
 :jobsnippet=&gt;                                       
  "There will be a wide variety of sites, such as simple brochure WP sites...",
 :date=&gt;"2022-03-17"} 
</pre>

    puts is22.list

<pre>
 1. Embedded Developer
 2. Front End Developer                                
 3. Front End Developer                                
 4. Backend Developer                                  
 5. Graduate Software Engineer                         
 6. Software Engineer                                  
 7. Frontend Software Development Internship           
 8. Graduate Web Developer                             
 9. Frontend Engineer                                  
10. Wordpress Developer                                
11. Front end developer                                
12. Data Visualisation Developer                       
13. 094979 R3 Application Developer                    
14. 094982 eHealth Specialist Developer                
15. Software Engineer     
</pre>

    is22.page(15)

<pre>
 =&gt; 
{:title=&gt;"Software Engineer",                
 :company=&gt;"Russell Taylor",                 
 :companylink=&gt;nil,                          
 :location=&gt;"Dunfermline",                   
 :worklocation=&gt;"Remote",                    
 :note=&gt;nil,                                 
 :date=&gt;"2022-03-15",                        
 :desc=&gt;                                     
  "&lt;div id='jobDescriptionText' class='jobsearch-jobDescriptionText'&gt;&lt;p&gt;Russe...
</pre>

s22.page(1)
<pre>
{:title=&gt;"Embedded Developer",                    
 :company=&gt;"Ocean Information Services Ltd",      
 :companylink=&gt;nil,                               
 :location=&gt;"Edinburgh EH2",                      
 :worklocation=&gt;nil,                              
 :note=&gt;nil,                                      
 :date=&gt;"2022-03-10",                             
 :desc=&gt;                                          
  "&lt;div id='jobDescriptionText' class='jobsearch-jobDescriptionText'&gt;&lt;p&gt;Ocean Informati
</pre>

## Resources

* indeed_scraper2022 https://rubygems.org/gems/indeed_scraper2022

indeed scraper gem indeed_scraper2022 indeedscraper
