set -e

tenureId=$1
newPRN=$2

function get_env_var {
  grep -oP "^$1=\K[^\s]+$" '.env' || echo ''
}

tenureBaseUrl="$(get_env_var 'TENUREBASEURL')"
tenureGetToken="$(get_env_var 'TENUREGETTOKEN')"
accountBaseUrl="$(get_env_var 'ACCOUNTBASEURL')"
accountPostToken="$(get_env_var 'ACCOUNTPOSTTOKEN')"

[[ -z $tenureBaseUrl || -z $tenureGetToken || -z $accountBaseUrl || -z $accountPostToken ]] \
  && (echo "Not ALL environment variables are set!"; exit 1)

tenureData=$(curl -sS --location --request GET "$tenureBaseUrl/tenures/$tenureId" \
  --header "Authorization: Bearer $tenureGetToken" \
  --header 'Content-Type: application/json'
)

commonMessage="\e[5m\033[31mFailed to retrieve data!\033[0m (for tenureId=\e[33m$tenureId\e[0m)"

fetchedTenureId=$(echo $tenureData | jq '.id') \
  || (echo -e "$commonMessage Unexpected response structure!\nAPI Response: $tenureData;"; exit 1)

[[ -z $fetchedTenureId || $fetchedTenureId = 'null' ]] \
  && (echo -e "$commonMessage TenureId is empty!\nAPI Response: $tenureData;"; exit 1)

tenureCreateEntity=$(echo $tenureData | jq ". | { \
  tenureId: .id, \
  tenureType: .tenureType, \
  fullAddress: .tenuredAsset.fullAddress, \
  primaryTenants: [\
    .householdMembers[] | { id: .id, fullName: .fullName } \
  ]\
}")

financeAccount="{ \
  \"createdBy\": \"PRN-fix account-create script\",
  \"paymentReference\": \"$newPRN\", \
  \"targetType\": \"Tenure\", \
  \"accountType\": \"Master\", \
  \"rentGroupType\": \"Tenant\", \
  \"agreementType\": \"Master Account\", \
  \"accountStatus\": \"Active\", \
  \"targetId\": \"$tenureId\", \
  \"tenure\": $tenureCreateEntity
}"

postResult=$(curl -sS --location --request POST "$accountBaseUrl/accounts" \
  --header "Authorization: Bearer $accountPostToken" \
  --header 'Content-Type: application/json' \
  --data-raw "$financeAccount"
)

postError="\e[5m\033[31mUpdate possibly failed!\033[0m TenureId=\e[33m$tenureId\e[0m;\nAPI Response: $postResult;"

createdAccountId=$(echo "$postResult" | jq '.id') || (echo -e $postError; exit 1)

[[ -n $createdAccountId && $createdAccountId != 'null' ]] \
  && (echo $postResult | jq '. | {tenure_id: .targetId, account_id: .id, new_payment_ref: .paymentReference}') \
  || (echo -e $postError; exit 1)
