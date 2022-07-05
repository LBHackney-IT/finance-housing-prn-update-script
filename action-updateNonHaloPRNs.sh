set -e

tenureId=$1
newPRN=$2

function get_env_var {
  key=$1
  grep -oP "^$key=\K[^\s]+$" '.env'
}

baseUrl="$(get_env_var 'BASEURL')"
getToken="$(get_env_var 'GETTOKEN')"
patchToken="$(get_env_var 'PATCHTOKEN')"

accountId=$(curl -sS --location --request GET "$baseUrl/accounts?targetId=$tenureId" \
  --header "Authorization: Bearer $getToken" \
  --header 'Content-Type: application/json' | \
  jq '.accountResponseList[0].id' | \
  grep -oP '(?<=")[^"]+(?=")'
) || echo -e "\n\e[5m\033[31mNo Accounts Id!\033[0m TenureId=$tenureId;"

[[ -z "$accountId" ]] && exit 1; # Terminate execution

result=$(curl -sS --location --request PATCH "$baseUrl/accounts/$accountId" \
  --header "Authorization: Bearer $patchToken" \
  --header 'Content-Type: application/json' \
  --data-raw "[
    {
      \"value\": \"$newPRN\",
      \"operationType\": 2,
      \"path\": \"paymentReference\",
      \"op\": \"replace\"
    }
  ]"
)

updatedAccId=$(echo "$result" | jq '.account_id')

[[ $updatedAccId != *null* ]] \
  && echo "$result" | jq '. | {account_id: .id, tenure_id: .targetId, new_payment_ref: .paymentReference}' \
  || (echo -e "\e[5m\033[31mUpdate failed!\033[0m TenureId=$tenureId;\nResult: $result;"; exit 1;)
