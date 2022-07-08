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
The core work is done by `action-{action_name}.sh` files. One of these is the `action-updateNonHaloPRNs.sh` action script file. This script processes only a sinle record per launch. To use it, you need to provide it with 2 arguments like so:
``` sh
./action-updateNonHaloPRNs.sh "the_tenure_id_of_the_record" "new_PRN_value"
```
Once it gets the 2 required parameters, it uses the __tenure id__ to fetch the _(finance)_ __account id__. Once it has the account id, it uses it to specify what record in the __Accounts__ table needs updating & updates it with the provided __new PRN__ value.

The `action-createMissingAccount` action script mimicks the behaviour of the Finance Account Listener usecase _(for the TenureCreatedEvent)_ [see here](https://github.com/LBHackney-IT/finance-account-listener/blob/ffaedeb600fe5dabbed2fdfc916a9f23f0945eaa/FinanceAccountListener/UseCase/AddNewAccountWhenTenureCreatedUseCase.cs). It pulls down the tenure using __tenure id__, filters down its fields & uses them for creating a (finance) account _(account gets created via account-api POST endpoing call)_. The PRN of the new account record is set to the provided __new PRN__ value.

The action scripts are expected to get called multiple times with differing parameters from within the `updateScript` script file __(Click on the file to see the example)__.

# Using the script
You should not use the `action-updateNonHaloPRNs.sh` directly, but rather run it via the `updateScript.sh`. You should use the _Google Sheets_ or _MS Office Excel_ to concatenate the record data from __bad PRNs__ spreadsheet in such a way that the result would be in a form of `./action-updateNonHaloPRNs.sh "tenureId_1" "newPRN_1"`. Once you have your update commands column, just copy out the entire column into the `updateScript.sh` file.

Run the update script by running the following command:
``` sh
./updateScript.sh
```

# Preferences
You can uncomment the `set -e` line at the top of the `updateScript.sh` to terminate its execution on any failure. If you do not prefer to be slowed down by failures, you can keep the `set -e` commented out. That way the `updateScript.sh` will continue to subsequent update commands despite the previous having failed. If you're doing the updating in the small enough batches, the log of the tenancy reference that has failed should still be in your terminal output _(depends on how many lines your terminal is configured to show before it starts clearing the top-most ones)_ by the time the `updateScript.sh` execution has finished.

# Extra Notes
 - Do not run `action-updateNonHaloPRNs` against the bad PRN records taken from HALO. HALO cases are an entirely different edge case that either needs a similar, yet separate script. To update the HALO ones with missing finance accounts, use: `action-createMissingAccount`.
 - Don't have multiple environment variables that have identical names uncommented at the same time within the `.env` file. The custom function that is written to extract environment variables from the `.env` file is __assuming__ that only a single __uncommented__ environment variable with the same name exists.
 - The script could in theory read a CSV file and there wouldn't be a needed for string manipulation in Google Sheets. However, adding such functionality would take a considerable effort, which does not justify the effort it would save.
 - For the action script to work all of the environment variables it's trying to import need to be specified. The `action-createMissingAccount` will complain about it, however, at the current state the `action-updateNonHaloPRNs` will fail silently.
