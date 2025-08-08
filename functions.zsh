get_certificate(){
	openssl s_client -showcerts -servername $1 -connect $1:443 2> /dev/null | openssl x509 -inform pem -noout -text
}



get_certificate_nuclei(){
	input=""
	while read line
	do
		input="$input$line\n"
	done < "${1:-/dev/stdin}"
	echo $input | nuclei -t ~/bugbounty-tools/nuclei-private-templates/ssl-dns-names.yaml -silent -j | jq -r '.["extracted-results"][]' | sort -u
}



get_asn(){
	curl -s https://api.bgpview.io/ip/$1 | jq -r ".data.prefixes[] | {prefix: .prefix, ASN: .asn.asn}"
}



nice_naabu(){
	input=""
	while read line && [[ "$line" != "END_OF_INPUT" ]]; do
		input="$input$line\n"
	done
	echo $input | naabu -p 80,8000,8080,8880,2052,2082,2086,2095,443,2053,2083,2087,2096,8443,10443 -silent 
}



get_ptr(){
	input=""
	while read line && [[ "$line" != "END_OF_INPUT" ]]; do
		input="$input$line\n"
	done
	echo $input | dnsx -silent -resp-only -ptr
}



crtsh(){
	query=$(cat <<-END
			SELECT
				ci.NAME_VALUE
			FROM
				certificate_and_identities ci
			WHERE
				plainto_tsquery('certwatch', '$1') @@ identities(ci.CERTIFICATE)
END
)
	echo "$query" | psql -t -h crt.sh -p 5432 -U guest certwatch | sed 's/ //g' | grep -E ".*.\.$1" | sed 's/*\.//g' | tr '[:upper:]' '[:lower:]'	| sort -u
}



github_scan(){
	DOMAIN=$1
	q=$(echo $DOMAIN | sed -e 's/\./\\\./g')
	src search -json '([a-z\-]+)?:?(\/\/)?([a-zA-Z0-9]+[.])+('${q}') count:5000 fork:yes archived:yes' | jq -r '.Results[] | .lineMatches[].preview, .file.path' | grep -oiE '([a-zA-Z0-9]+[.])+('${q}')' | awk '{ print tolower($0) }' | sort -u
}




fback() {                  
python3 ~/bugbounty-tools/BackupKiller/fback.py "$@"
}




robofinder() {
python3 ~/bugbounty-tools/robofinder/robofinder.py "$@"
}



wlist_maker(){
	seq 1 100 > list.tmp
	echo $1 >> list.tmp
	seq 101 300 >> list.tmp
	echo $1 >> list.tmp
	seq 301 600 >> list.tmp
}



nice_wayback(){
	while read line
	do
		host=$(echo $line | unfurl format %d)
		echo "$line" | waybackurls | grep -Eiv '\.(css|jpg|jpeg|png|svg|img|gif|exe|mp4|flv|pdf|doc|ogv|webm|wmv|webp|mov|mp3|m4a|m4p|ppt|pptx|scss|tif|tiff|otf|woff|woff2|bmp|ico|eot|htc|swf|rtf|image|rf)' | sort -u | tee ${host}.waybackyrls
		done < "${1:-/dev/stdin}"
}


x9() {                  
python3 ~/bugbounty-tools/X9/x9.py "$@"
}


extract_js_files() {
    local input_file="$1"

    if [[ ! -f $input_file ]]; then
        echo "File not found: $input_file"
        return 1
    fi

    # Extract lines ending with .js and display them
    grep -E '\.js($|\?)' "$input_file"
}


linkfinder(){
python3 ~/bugbounty-tools/LinkFinder/linkfinder.py "$@"
}


wayback_downloader() {
python3 ~/bugbounty-tools/wayback_downloader/wayback_downloader.py "$@"
}



js_param_extractor() {
python3 ~/bugbounty-tools/param_extractor/js-param-extractor.py "$@"
}

html_param_extractor() {
python3 ~/bugbounty-tools/param_extractor/html-param-extractor.py "$@"
}

combine-domain-path() {
python3 ~/bugbounty-tools/param_extractor/combine-domain-path.py "$@"
}


nice_masscan() {
masscan $1 --open --ports 80,443,444,1443,1455,2000,2020,2052,2053,2082,2083,2086,2087,2095,2096,2222,3000,3003,3030,3300,3306,3333,4000,4040,4400,4440,4443,4444,4900,5000,5030,5050,5432,5500,5555,6000,6100,6666,7000,7007,7008,7700,7777,8000,8080,8090,8100,8180,8200,8300,8400,8443,8500,8600,8700,8800,8880,8888,8899,9000,9009,9040,9050,9080,9090,9100,9200,9300,9400,9500,9898,9900,9999,10443,27017 -oL masscan-res.txt && grep "open" masscan-res.txt | awk '{print $4 ":" $3}'
}


nice_masscan_list() {
masscan -iL $1 --open --ports 80,443,444,1443,1455,2000,2020,2052,2053,2082,2083,2086,2087,2095,2096,2222,3000,3003,3030,3300,3306,3333,4000,4040,4400,4440,4443,4444,4900,5000,5030,5050,5432,5500,5555,6000,6100,6666,7000,7007,7008,7700,7777,8000,8080,8090,8100,8180,8200,8300,8400,8443,8500,8600,8700,8800,8880,8888,8899,9000,9009,9040,9050,9080,9090,9100,9200,9300,9400,9500,9898,9900,9999,10443,27017 -oL masscan-res.txt && grep "open" masscan-res.txt | awk '{print $4 ":" $3}'
}


httpx_full() {
input=""
while read line && [[ "$line" != "END_OF_INPUT" ]]
do
input="$input$line\n"
done
echo $input | httpx -silent -follow-host-redirects -title -status-code -cdn -tech-detect -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" -H "Referer: https://$input" -threads 1
}


httpx_full_chrome() {
input=""
while read line && [[ "$line" != "END_OF_INPUT" ]]
do
input="$input$line\n"
done
echo $input | httpx -system-chrome -silent -follow-host-redirects -title -status-code -cdn -tech-detect -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" -H "Referer: https://$input" -threads 1
}


get_subs() {
domain=$1
echo "[Domain] = $1"
echo "[crtsh]"
crtsh $domain | grep -v "*" | sort -u > ${ddomain}.subs
echo "[Subfinder]"
subfinder -d $domain -all -silent | anew ${domain}.subs
echo "[abuseipdb]"
abuseipdb $domain | anew ${domain}.subs
}


abuseipdb() {
curl -s "https://www.abuseipdb.com/whois/$1" -H "User-agent: Chrome" | grep -E '<li>\w.*</li>' | sed -E 's/<\/?li>//g' | sed -e "s/$/.$1/"
}



dns_wlist_maker() {
cat $1 | dnsgen -w $2 - | sort -u > /tmp/dnsgen.tmp
altdns_fix -i $1 -w $2 -o /tmp/altdns.tmp
cat /tmp/altdns.tmp /tmp/dnsgen.tmp > dnsbrute_wordlist.txt
rm -rf /tmp/dnsgen.tmp
rm -rf /tmp/altdns.tmp
}



altdns_fix() {
source ~/bugbounty-tools/altdns/env/bin/activate
altdns "$@"
deactivate
}



get_ip_asn() {
input=""
while read line
do
curl -s https://api.bgpview.io/ip/$line | jq -r ".data.prefixes[0].asn.asn"
done
}




get_asn_details() {
input=""
while read line
do
curl -s https://api.bgpview.io/asn/$line | jq -r ".data | {asn: .asn, name: .name, des: .description_short, email: .email_contacts}"
done < "${1:-/dev/stdin}"
}



param_maker() {
	filename="$1"
	value="$2"
	counter=0
	query_string="?"
	while IFS= read -r keyword
	do
		if [ -n "$keyword" ]
		then
			counter=$((counter+1))
			query_string="${query_string}${keyword}=${value}${counter}&"
		fi
		if [ $counter -eq 25 ]
		then
			echo "${query_string%?}"
			query_string="?"
			counter=0
		fi
	done < "$filename"
	if [ $counter -gt 0 ]
	then 
		echo "${query_string%?}"
	fi
}


nice_gau() {	
	host=$(echo $1 | unfurl format %d)
	echo "$1" | gau | grep -Eiv '\.(css|jpg|jpeg|png|svg|img|gif|exe|mp4|flv|pdf|doc|ogv|webm|wmv|webp|mov|mp3|m4a|m4p|ppt|pptx|scss|tif|tiff|otf|woff|woff2|bmp|ico|eot|htc|swf|rtf|image|rf)' | sort -u | tee ${host}.nice_gau
}



nice_katana() {
	while read line
	do
		host=$(echo $line | unfurl format %d)
		echo $line | katana -js-crawl -jsluice -known-files all -automatic-form-fill -silent -crawl-scope $host -extension-filter css,jpg,jpeg,png,svg,img,gif,mp4,flv,pdf,doc,ogv,webm,wmv,webp,mov,mp3,m4a,m4p,ppt,pptx,scss,tif,tiff,ttf,otf,woff,woff2,bmp,ico,eot,htc,swf,rtf,image,rf,txt,ml,ip -headers "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36" | tee ${host}.katana
	done
}



nice_passive() {          
python3 ~/zsh-configs/nice_passive.py "$@"
}


favicon() {
python3 ~/zsh-configs/favicon.py "$@"
}

dns_brute_full () {
	echo "cleaning..."
	rm -f "$1.wordlist $1.dns_brute $1.dns_gen"
	echo "making static wordlist..."
	awk -v domain="$1" '{print $0"."domain}' "$WL_PATH/subdomains/assetnote-merged.txt" >> "$1.wordlist"
	echo "making 4 chars wordlist..."
	awk -v domain="$1" '{print $0"."domain}" "$WL_PATH/4-lower.txt" >> "$1.wordlist"
	echo "shuffledns static brute-force..."
	shuffledns -list $1.wordlist -d $1 -r ~/.resolvers -m $(which massdns) -mode resolve -silent | tee $1.dns_brute 2>&1 > /dev/null
	echo "[+] finished, total $(wc -l $1.dns_brute) resolved..."
	echo "running subfinder..."
	subfinder -d $1 -all | dnsx -silent | anew $1.dns_brute 2>&1 > /dev/null
	echo "[+] finished, total $(wc -l $1.dns_brute) resolved..."
	echo "running DNSGen..."
	cat $1.dns_brute | dnsgen -w $WL_PATH/subdomains/words.txt > $1.dns_gen 2>&1 > /dev/null
	echo "finished with $(wc -l $1.dns_gen) words..."
	echo "shuffledns dynamic brute-force on dnsgen results..."
	shuffledns -list $1.dns_gen -d $1 -r ~/.resolvers -m $(which massdns) -mode resolve -silent | anew $1.dns_brute 2>&1 > /dev/null
	echo "[+] finished, total $(wc -l $1.dns_brute) resolved..."
}
