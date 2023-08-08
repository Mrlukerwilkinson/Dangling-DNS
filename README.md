<h2>Azure DNS - Avoid subdomain takeover – find and cut your Dangling DNS entries!</h2>
<br>
This post describes a common threat of subdomain hijacking, also known as subdomain takeover, and provides some steps you can take to mitigate it. The following post is for Security Engineers / Administrators that manage public Azure DNS Zones in a cloud environment that uses multiple Azure Services, including Azure App Services. The following process is focused on Azure Services, however, it can be used for any other service, so change and fit the requirements for your needs.

<h2>🕵️‍♂️🌐 What is subdomain hijacking? </h2>
<p>
Subdomain hijacking is not new and is an increasingly common vulnerability due to cloud services' rapid and easy provision.  Businesses regularly spin up cloud-based services for dev, test, and prod environments and don't always de-provision services following best practices.
</p>

<p>
Subdomain hijacking occurs when a DNS record - typically a CNAME record (for the sake of this post), points to a service that has been de-provisioned, and the DNS record pointing to the service is still active - also called dangling DNS entries. The domain that the DNS record points to becomes available, and attackers can take ownership of this domain and then publish malicious content. This may be a common vulnerability if your organisation uses Azure App Service or AWS Elastic Beanstalk and the service is not de-provisioned properly at the end of its lifecycle. 
</p>
<p>
This post focuses on Microsoft Azure services. For additional background, you can find further explanations from Microsoft’s article on <a href="https://learn.microsoft.com/en-us/azure/security/fundamentals/subdomain-takeover" target="_blank" >how to prevent dangling DNS entries and avoid subdomain takeover.</a>
</p>

<h2>🔒🔓🛡️💻🔥 Attack Scenario </h2>
<ol>
<li>Your company spins up an Azure App Service for a TEST/UAT/PROD environment.</li>
<li>Your company creates a CNAME record to point to the new App Service.</li>
<li>Your company completes testing and deletes the App Service but does not delete the CNAME record pointing to the App Service’s unique URL. </li>
<li>An attacker spins up an Azure App Service and claims your company's previous domain. As the DNS records already exist in your company’s public DNS, your domain now points to the attacker’s-controlled environment.</li>
<li>The attacker can now host any content, and your company's domain is now potentially serving up malicious or reputationally damaging content.</li>
<li>Your company's Cyber Threat Team alerts you to the attack - if you're fortunate enough to have one!</li>
</ol>

  
<h2>☁️🔵 Microsoft Domains Susceptible to Domain Takeover</h2>
<p>After following the Microsoft Article referenced above, if you’re not satisfied with the results and want to dig deeper into identifying potential dangling DNS entries, you can refer to the auditing tool <a href="https://github.com/EdOverflow/can-i-take-over-xyz" target"_blank">can-i-take-over-xyz</a>. 
<br/>
  
  Can-i-take-over-xyz is a curated list of services, whether they are vulnerable to dangling DNS, the list of the domains affected and the fingerprint you can use to identify potential dangling DNS entries. </p>
<p>
Referring to can-i-take-over-xyz's list of Microsoft Azure domains vulnerable to subdomain takeover, you can see multiple Azure domains are affected, as shown in Figure 1 below.

![image](https://github.com/Mrlukerwilkinson/Dangling-DNS/assets/140768032/a19228b9-b44c-4790-a8d9-7c4cb772662a)
*Figure 1: Microsoft Azure Domains susceptible to domain takeover.*

Image Source: [can-i-take-over-xyz](https://github.com/EdOverflow/can-i-take-over-xyz)
</p>

<h2>🕵️‍♂️🔍 Identifying DNS records in your Environment that may be vulnerable to domain takeover</h2>
<p>Now we have a list of potential domains that are possible targets of domain takeovers; the first step is to audit your public DNS environment for any records that contain the values listed in Figure 1 above.
<br/>
  
Download and run the script <a href="https://github.com/Mrlukerwilkinson/Dangling-DNS/blob/main/AzureDNS-Keyword-Search-All-Records.ps1" target="_blank">AzureDNS-Keyword-Search-All-Records.ps1</a>, be sure to update the subscription and resource group values with your Azure DNS details!
<br>

The script should search through your Azure DNS Zones and locate any DNS Records that contain the Microsoft Azure domains listed in Figure 1 above, and export the record name, type, value and DNS Zone to a CSV file for review. 
<br>

<b>Note:</b> The script performs a search based on a single keyword, as this is a proof-of-concept, I didn't spend much time on updating it to include multiple keywords so you will need to modify the keyword values and run the script multiple times to search for all possible domains as listed in Figure 1. 
<h2>✅📝✅ Check DNS Records for Dangling DNS entries</h2>
Now we have a list of DNS records from the environment that contain the known Microsoft Azure domains used in common services such as App Service, it's time to perform a DNS lookup of the domain(s) to determine if the domain is actually resolvable.

To make this step easier and automate the process, we will grab the values from the CSV file created earlier, in particular, the domain's value. Export this list to a TXT file, with each domain on a separate line, and then update the input_file value in the <a href="https://github.com/Mrlukerwilkinson/Dangling-DNS/blob/main/check_domain_status.sh" target="_blank">check_domain_status.sh</a> script with your TXT file name / location. An example of this TXT file can be seen below in Figure 2.

![image](https://github.com/Mrlukerwilkinson/Dangling-DNS/assets/140768032/c65a36dc-521e-41d7-893f-9cb250b5ade7)

*Figure 2: Example list of domains to check for dangling DNS entries.*


Now we have a list of domains to check, download and run the <a href="https://github.com/Mrlukerwilkinson/Dangling-DNS/blob/main/check_domain_status.sh" target="_blank">check_domain_status.sh</a> script to perform a <a href="https://linux.die.net/man/1/dig" target="_blank">dig</a> lookup on all domains listed in the TXT file, this script reviews the header section of the output for the status field, then exports the domain and status to a CSV file for review. The common status values that you might encounter include:
<ol>
  <li><b>NOERROR:</b> The query was successful and returned the expected response.</li>
  <li><b>NXDOMAIN:</b> The queried domain does not exist in the DNS.</li>
  <li><b>SERVFAIL:</b> The DNS server encountered an issue while processing the query, resulting in a failure to provide a valid response.</li>
  <li><b>REFUSED:</b> The DNS server refused to respond to the query, possibly due to policy or configuration.</li>
  <li><b>FORMERR:</b> The query format is incorrect, and the DNS server cannot process it.</li>
  <li><b>NOTIMP:</b> The DNS server does not support the requested query type.</li>
  <li><b>YXDOMAIN:</b> The queried domain exists, contrary to expectations.</li>
  <li><b>YXRRSET:</b> The queried RRset (Resource Record Set) exists, contrary to expectations.</li>
  <li><b>NXRRSET:</b> The queried RRset does not exist as expected.</li>
  <li><b>NOTAUTH or NOTAUTHORITY:</b> The DNS server is not authoritative for the queried domain.</li>
  <li><b>NOTZONE:</b> The queried name is not in the zone covered by the DNS server.</li>
  <li><b>BADSIG:</b> The DNSSEC signature on the response is invalid.</li>
</ol>
These status values provide information about the outcome of the DNS query and help diagnose any issues with domain resolution. Because we are looking for domains that are no longer valid, if you refer to the fingerprint listed in Figure 1, we are interested in the <b>NXDOMAIN</b> status.
<br>
After executing the script, you should receive output to the terminal and a CSV file with the results, an example can be seen in Figure 3 below.

![image](https://github.com/Mrlukerwilkinson/Dangling-DNS/assets/140768032/5c6aa173-4d81-4a3c-8fb0-ea46f5dde6d3)

*Figure 3: Example output of DIG lookup of domains.*

As you can see if Figure 3 above, the first two domains return a <b>NOERROR</b> with the third domain returning an <b>NXDOMAIN</b> status, which according to <a href="https://github.com/EdOverflow/can-i-take-over-xyz" target="_blank">Can-i-take-over-xyz<a/> is the Fingerprint for possible susceptible Azure Services. 

If you want to further review the domains in quesiton to confirm if they are active, you can run the following curl command to retrieve the HTTP Status code of each domain:
````
while read -r domain; do
    status_code=$(curl -o /dev/null -s -w "%{http_code}" "http://$domain")
    echo "$domain: $status_code"
done < domain_list.txt
````

An example of this output can be seen in Figure 4 below, where the Azure URL in question returned a non-standard HTTP status code, which may indicate potential issues with the domain.

![image](https://github.com/Mrlukerwilkinson/Dangling-DNS/assets/140768032/506d4150-bd97-4862-ac7d-5ab9ac160c0e)

*Figure 4: Curl request to obtain HTTP status codes of domains in question.*


<h2>🎉🏁🎉Conclusion🎉🏁🎉</h2>

After obtaining a list of DNS records in your environment that are potentially vulnerable to a domain takeover attack, and then performing a status check on each domain, you should hopefully now be able to identify what records are no longer resolving and can be removed from your public DNS to mitigate any risk associated with a potential domain takeover attack. After performing a DIG lookup on the domains and receiving the status code, such as <b>NXDOMAIN</b>, it's always beneficial to validate the findings with other methods such as the curl request to obtain the HTTP status codes. 

This post focused on Azure services and Azure DNS, however, this process can be adapted and modified to suit your specific needs so feel free to copy and improve the process as you see fit! 

