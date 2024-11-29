get_certificate(){
	echo | openssl s_client -showcerts -servername $1 -connect $1 2>/dev/null | openssl x509 -inform pem -noout -text
}



get_certificate_nuclei(){
	nuclei -t ~/nuclei-templates/ssl/ssl-dns-names.yaml -silent -j | jq -r '.["extracted-results"][]' | sort -u
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




