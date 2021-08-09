# @ Vasudeva Manikandan/Arnab Ghosh
# Purpose: Convert XLS file to JSON 
# Generated JSON can be used as an argument to OCI CLI commands to create Weblogic Instance

# Call python to convert xls to json

echo "Setting up OCI CLI environment variables"

. ./setENV_destroy.sh

echo "OCI CLI Environment has been setup and junk json files have been removed successfully"

echo "Converting EXCEL to JSON"
python xls_to_json.py


# Validate JSON

echo "Validating JSON\n"

./valiJSON.sh

# Get Compartment ID
comp_ocid=`grep -i "compartment_oci" input.json | cut -d ":" -f2 | tr -d " "| tr -d \" | tr -d ",$"`
echo $comp_ocid

# Create Stack 

stack_id=`oci resource-manager stack create --config-source $config_source --compartment-id $comp_ocid --display-name "$display_name" --description "$stack_description" --terraform-version "0.12.x" --query 'data.id' --raw-output`

echo "Updating Job with input.json"

yes | oci resource-manager stack update --stack-id $stack_id --variables file://input.json

echo "Creating Plan Job"
CREATED_PLAN_JOB_ID=$(oci resource-manager job create-plan-job --stack-id $stack_id --max-wait-seconds 120 --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
echo "Created Plan Job Id: ${CREATED_PLAN_JOB_ID}"

jobstate=`oci resource-manager job get --job-id $CREATED_PLAN_JOB_ID --query 'data."lifecycle-state"' --raw-output`

if [[ "$jobstate" = "SUCCEEDED" ]]
then
echo "Creating Apply Job"
CREATED_APPLY_JOB_ID=$(oci resource-manager job create-apply-job --stack-id $stack_id --execution-plan-strategy FROM_PLAN_JOB_ID --execution-plan-job-id "$CREATED_PLAN_JOB_ID" --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
echo "Created Apply Job Id: ${CREATED_APPLY_JOB_ID}"
echo "Getting Apply Job Logs"
echo $(oci resource-manager job get-job-logs --job-id $CREATED_APPLY_JOB_ID) > $APPLY_JOB_LOGS_FILE
echo "Saved Job Logs to $APPLY_JOB_LOGS_FILE"
else
echo "Plan job has FAILED. Please check in the OCI Console"
echo "Getting Plan Job Logs"
echo $(oci resource-manager job get-job-logs --job-id $CREATED_PLAN_JOB_ID) > $PLAN_JOB_LOGS_FILE
echo "Saved Job Logs to $PLAN_JOB_LOGS_FILE"
echo "Deleting Stack"
oci resource-manager stack delete --stack-id $stack_id --force
echo "Stack is deleted...Exit Complete"
exit 3
fi

echo "Getting Job Terraform state"
oci resource-manager job get-job-tf-state --job-id $CREATED_APPLY_JOB_ID --file $JOB_TF_STATE
echo "Saved Job TF State to $JOB_TF_STATE"

sleep 1m

echo "Creating Destroy Job"
CREATED_DESTROY_JOB_ID=$(oci resource-manager job create-destroy-job --stack-id $stack_id --execution-plan-strategy=AUTO_APPROVED --wait-for-state SUCCEEDED --query 'data.id' --raw-output)
echo "Created Destroy Job Id: ${CREATED_DESTROY_JOB_ID}"

echo "Deleting Stack"
oci resource-manager stack delete --stack-id $stack_id --force

echo "Script Finished"