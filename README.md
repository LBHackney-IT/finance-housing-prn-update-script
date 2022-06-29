# Payment Reference Number update Script
This script is used to update the incorrect payment reference numbers within the 'Accounts' DynamoDB table records. It doesn't update the DynamoDB table directly, but instead it uses the account-api's PATCH endpoint to do the job.

# Setup
1. Make sure you have the `jq` installed. You can do this by following the official instructions found [here](https://stedolan.github.io/jq/download/).

2. Create the `.env` file based on `.env.sample` by running:
  ``` sh
    cp .env.sample .env
  ```

3. Populate the `.env` file with the required environment variables.

# How it works?
The core work is done by the `action-updateNonHaloPRNs.sh` script file. This script processes only a sinle record. To use it, you need to provide it with 2 arguments like so: `action-updateNonHaloPRNs.sh "the_tenure_id_of_the_record" "new_PRN_value"`. Once it gets the 2 required parameters, it uses the __tenure id__ to fetch the _(finance)_ __account id__. Once it has that, it uses it to specify what record in the __Accounts__ table needs deleting & updates it with the provided _new PRN__ value.

# Using the script
You should not use the `action-updateNonHaloPRNs.sh` directly, but rather run it via the `updateScript.sh`. You should use the Google Sheets or MS Office Excel to concatenate the record data from __bad PRNs__ spreadsheet in such a way that the result would be `action-updateNonHaloPRNs.sh "tenureId_1" "newPRN_1"`. Then just copy out the entire column into the `updateScript.sh`.

Run the update script by running `./updateScript.sh` command.

# Preferences
You can uncomment the `set -e` line at the top of the `updateScript.sh` to terminate its execution on any failure. If you do not prefer to be slowed down by failures, you can keep the `set -e` commented out. That way the `updateScript.sh` will continue to subsequent update commands despite the previous having failed. If you're doing the updating in the small enough batches, the log of the tenancy reference that has failed should still be in your terminal output by the time the `updateScript.sh` execution has finished.

# Extra Notes
 - Do not run this against the bad PRN records taken from HALO. HALO cases are an entirely different edge case that either needs a similar, yet separate script.
 - Don't have multiple environment variables uncommented at the same time within the `.env` file. The custom function that is written to extract environment variables from the `.env` file is __assuming__ that only a single __uncommented__ environment variable with the same name exists.
