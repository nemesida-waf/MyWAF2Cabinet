#!/bin/bash

##
# Settings
##

## Example:
## lic_key="you_lic_key"
lic_key=""

## Example:
## nw_api_url="http://example.com:8080/nw-api/"
nw_api_url=""

## Example:
## sys_proxy="http://example.com:3128"
sys_proxy=""

## Example:
## api_proxy="http://example.com:3128"
api_proxy=""

##
# Settings
##

tmp_dir="/tmp/nwaf"

if [[ "$sys_proxy" == "" ]]; then sys_proxy="--noproxy '*'"; else sys_proxy="--proxy $sys_proxy"; fi
if [[ "$api_proxy" == "" ]]; then api_proxy="--noproxy '*'"; else api_proxy="--proxy $api_proxy"; fi

export http_proxy=""
export https_proxy=""

wl()
{

  curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_wl?extended=yes --data "key=$lic_key" | grep -v "{'status': 'success'}" > "$tmp_dir/wl"
  sleep 1
  readarray wl_array < "$tmp_dir/wl"
  for wl in "${wl_array[@]}"
  do
    wl=$(echo "$wl" | sed 's/'\''/"/g')
    active=$(echo "$wl" | awk '{print$4}' | awk '{print tolower($0)}')
    id=$(echo "$wl" | awk '{print$6}' | awk -F ':' '{print $2}')
    domain=""
    mz=""
    extension=""
    string=$(echo "$wl" | awk '{print$7}')
    if [[ $(echo "$string" | grep -o -E '^domain') == "domain" ]]
    then
      domain=$(echo "$string" | awk -F '=' '{print $2}')
    elif [[ $(echo "$string" | grep -o -E '^"Z:') == '"Z:' ]]
    then
      string=$(echo "$string" | awk -F '"Z:' '{print $2}' | rev | cut -c 2- | rev)
      IFS='|' read -r -a array_Z <<< "$string"
      for element in "${array_Z[@]}"
      do
        if [[ $(echo "$element" | grep -o -E '^\$') == '$' ]]
        then
          if [[ "$extension" == "" ]]
          then
            extension="$element"
          else
            extension="$extension|$element"
          fi
        else
          if [[ "$mz" == "" ]]
          then
            mz="$element"
          else
            mz="$mz|$element"
          fi
        fi
      done
    fi

    string=$(echo "$wl" | awk '{print$8}')
    if [[ $(echo "$string" | grep -o -E '^domain') == "domain" ]]
    then
      domain=$(echo "$string" | awk -F '=' '{print $2}')
    elif [[ $(echo "$string" | grep -o -E '^"Z:') == '"Z:' ]]
    then
      string=$(echo $string | awk -F '"Z:' '{print $2}' | rev | cut -c 2- | rev)
      IFS='|' read -r -a array_Z <<< "$string"
      for element in "${array_Z[@]}"
      do
        if [[ $(echo "$element" | grep -o -E '^\$') == '$' ]]
        then
          if [[ "$extension" == "" ]]
          then
            extension="$element"
          else
            extension="$extension|$element"
          fi
        else
          if [[ "$mz" == "" ]]
          then
            mz="$element"
          else
            mz="$mz|$element"
          fi
        fi
      done
    fi
    result=$(curl -s $api_proxy "${nw_api_url}set_dyn_wl" --header 'Content-type: application/json' --data '{ "key": "'"$lic_key"'", "add": {"rl_id": "'"$id"'", "active": '"$active"', "domain": "'"$domain"'", "mz": "'"$mz"'", "extension": "'"$extension"'" } }' | grep -o 'success')
    if [[ "$result" != "success" ]]; then echo "Error add $wl"; fi
  done

}

erl()
{

  curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_erl?extended=yes --data "key=$lic_key" | grep -v "{'status': 'success'}" > "$tmp_dir/erl"
  sleep 1
  readarray erl_array < "$tmp_dir/erl"
  for erl in "${erl_array[@]}"
  do
    ip="$(echo "$erl" | jq .ip | awk -F'"' '{print$2}')"
    lm="$(echo "$erl" | jq .lm)"
    ua="$(echo "$erl" | jq .ua | awk -F'"' '{print$2}')"
    api="$(echo "$erl" | jq .api)"
    url="$(echo "$erl" | jq .url | awk -F'"' '{print$2}')"
    args="$(echo "$erl" | jq .args | awk -F'"' '{print$2}')"
    body="$(echo "$erl" | jq .body | awk -F'"' '{print$2}')"
    noban="$(echo "$erl" | jq .noban)"
    active="$(echo "$erl" | jq .active)"
    cookie="$(echo "$erl" | jq .cookie | awk -F'"' '{print$2}')"
    domain="$(echo "$erl" | jq .domain | awk -F'"' '{print$2}')"
    country="$(echo "$erl" | jq .country | awk -F'"' '{print$2}')"
    referer="$(echo "$erl" | jq .referer | awk -F'"' '{print$2}')"
    no_cookie="$(echo "$erl" | jq .no_cookie)"
    other_headers="$(echo "$erl" | jq -c .other_headers)"

    result=$(curl -s $api_proxy "${nw_api_url}set_dyn_erl" --header 'Content-type: application/json' --data '{ "key": "'"$lic_key"'", "add": { "ip": "'"$ip"'", "other_headers": '"$other_headers"', "referer": "'"$referer"'", "ua": "'"$ua"'", "cookie": "'"$cookie"'", "body": "'"$body"'", "args": "'"$args"'", "url": "'"$url"'", "domain": "'"$domain"'", "api": '"$api"', "country": "'"$country"'", "active": '"$active"', "lm": '"$lm"', "noban": '"$noban"', "no_cookie": '"$no_cookie"' } }' | grep -o 'success')
    if [[ "$result" != "success" ]]; then echo "Error add ERL: $erl"; fi
  done

}

bl()
{

    curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_bl --data "key=$lic_key" | grep -v "{'status': 'success'}" > "$tmp_dir/bl"
    sleep 1
    readarray bl_array < "$tmp_dir/bl"
    bl=""
    for ip in "${bl_array[@]}"
    do
      ip=$(echo $ip | sed 's/'\''/"/g')
      if [[ "$bl" == "" ]]
      then
        bl='"'$ip'"'
      else
        bl="$bl ,\"$ip\""
      fi
    done

    result=$(curl -s $api_proxy "${nw_api_url}set_dyn_bl" --header 'Content-type: application/json' --data '{ "key": "'"$lic_key"'", "set": { "active": "true", "bl": ['"$bl"'] } }' | grep -o 'success')
    if [[ "$result" != "success" ]]; then echo "Error add BL: $bl"; fi

}

vhosts_list()
{

  result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_vhosts_list --data "key=$lic_key" | sed "s/'\[/\[/g" | sed "s/\]'/\]/g" | sed -e "s|'|\"|g")
  vhosts_list=$(echo $result | jq -c .vhosts_list)

  result=$(curl -s $api_proxy "${nw_api_url}set_vhosts_list" --header 'Content-type: application/json' --data '{ "key": "'"$lic_key"'", "vhosts_list": '"$vhosts_list"' }' | grep -o 'success')
  if [[ "$result" != "success" ]]; then echo "Error add vhosts list: $vhosts_list"; fi

}

set_dyn_settings()
{

  json="$1"
  param="$2"

  string=$(echo $json | jq .$param | awk -F '"' '{print $2}')
  if [[ "$string" != "" ]]
  then
    result=$(curl -s $api_proxy "${nw_api_url}set_dyn_settings" --header 'Content-type: application/json' --data '{ "key": "'"$lic_key"'", "set": { "'$param'": "'"$string"'" } }' | grep -o 'success')
    if [[ "$result" != "success" ]]; then echo "Error add Nemesida WAF settings: $param=$string"; fi
  fi

}

dyn_settings()
  {

  json=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_settings?format=json --data "key=$lic_key")

  set_dyn_settings "$json" "nwaf_limit"
  set_dyn_settings "$json" "nwaf_host_wl"
  set_dyn_settings "$json" "nwaf_host_lm"
  set_dyn_settings "$json" "nwaf_ai_extra_host_lm"
  set_dyn_settings "$json" "nwaf_ai_extra_host_wl"
  set_dyn_settings "$json" "nwaf_bf_detect_host_lm"
  set_dyn_settings "$json" "nwaf_ddos_detect_host_lm"
  set_dyn_settings "$json" "nwaf_mla_host_lm"
  set_dyn_settings "$json" "nwaf_put_body_exclude"
  set_dyn_settings "$json" "nwaf_rmq_host_exclude"
  set_dyn_settings "$json" "nwaf_post_body_exclude"
  set_dyn_settings "$json" "nwaf_ip_wl"
  set_dyn_settings "$json" "nwaf_ip_lm"
  set_dyn_settings "$json" "nwaf_openapi_ip_wl"
  set_dyn_settings "$json" "nwaf_openapi_ip_lm"
  set_dyn_settings "$json" "nwaf_openapi_url_wl"
  set_dyn_settings "$json" "nwaf_openapi_url_lm"
  set_dyn_settings "$json" "nwaf_url_wl"
  set_dyn_settings "$json" "nwaf_body_exclude"

}

set_mlc_settings()
{

  json="$1"
  param="$2"

  string=$(echo $json | jq .$param)
  if [[ "$string" != "" ]]
  then
    result=$(curl -s $api_proxy "${nw_api_url}set_mlc_settings" --header 'Content-type: application/json' --data '{ "key": "'"$lic_key"'", "set": { "'$param'": '"$string"' } }' | grep -o 'success')
    if [[ "$result" != "success" ]]; then echo "Error add Nemesida AI MLC settings: $param=$string"; fi
  fi

}

mlc_settings()
{

  json=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_mlc_settings?format=json --data "key=$lic_key")

  set_mlc_settings "$json" "main__ai_extra"
  set_mlc_settings "$json" "ddos__enable"
  set_mlc_settings "$json" "ddos__latest_only"
  set_mlc_settings "$json" "ddos__send_possible"
  set_mlc_settings "$json" "ddos__interval"
  set_mlc_settings "$json" "ddos__wl_ip"
  set_mlc_settings "$json" "ddos__wl_url"
  set_mlc_settings "$json" "brute__enable"
  set_mlc_settings "$json" "brute__latest_only"
  set_mlc_settings "$json" "brute__send_possible"
  set_mlc_settings "$json" "brute__interval"
  set_mlc_settings "$json" "brute__max_val"
  set_mlc_settings "$json" "brute__wl_host"
  set_mlc_settings "$json" "brute__brute_detect"
  set_mlc_settings "$json" "brute__flood_detect"

}

mkdir "$tmp_dir"

result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_wl?extended=yes --data "key=$lic_key" | grep "{'status': 'success'}" | wc -l)
if [[ "$result" == 1 ]]; then wl; fi

result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_erl?extended=yes --data "key=$lic_key" | grep "{'status': 'success'}" | wc -l)
if [[ "$result" == 1 ]]; then erl; fi

result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_bl --data "key=$lic_key" | grep "{'status': 'success'}" | wc -l)
if [[ "$result" == 1 ]]; then bl; fi

result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_vhosts_list --data "key=$lic_key" | grep "{'status': 'success'" | wc -l)
if [[ "$result" == 1 ]]; then vhosts_list; fi

result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_dyn_settings?format=json --data "key=$lic_key" | grep '"status": "success"' | wc -l)
if [[ "$result" == 1 ]]; then dyn_settings; fi

result=$(curl -s $sys_proxy https://nemesida-security.com/nw/agent/get_mlc_settings?format=json --data "key=$lic_key" | grep '"status": "success"' | wc -l)
if [[ "$result" == 1 ]]; then mlc_settings; fi
