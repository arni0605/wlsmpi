# @ Vasudeva Manikandan/Arnab Ghosh
# Purpose: Convert XLS file to JSON 
# Generated JSON can be used as an argument to OCI CLI commands to create Weblogic Instance

# Call python to convert xls to json

echo "Setting up OCI CLI environment variables"

. ./setENV.sh

echo "OCI CLI Environment has been setup and junk json files have been removed successfully"

echo "Converting EXCEL to JSON"
python xls_to_json.py
#sed 's/:$//g' out.txt > input.json

# Display output file
#cat input.json

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

echo "Plan Your Job.."

job_id=`oci resource-manager job create-plan-job --stack-id $stack_id --max-wait-seconds 120 --wait-for-state SUCCEEDED --config-file $config_file --query 'data.id' --raw-output`

jobstate=`oci resource-manager job get --job-id $job_id --query 'data."lifecycle-state"' --raw-output`

if [[ "$jobstate" = "SUCCEEDED" ]]
then
echo "Plan job succeeded..running Apply job"
appl_job_id=`oci resource-manager job create-apply-job --stack-id $stack_id --execution-plan-strategy FROM_PLAN_JOB_ID --execution-plan-job-id "$job_id" --config-file $config_file --query 'data.id' --raw-output`
else
echo "Plan Job has failed ...Exiting...Please check the OCI Console"
exit 3
fi

i=1
status="ACCEPTED"
echo -n "Checking Job Status.."

while [ $i -le 90 ]
 do
 echo -n ".." 
 status=`oci resource-manager job get --job-id $appl_job_id --query 'data."lifecycle-state"' --raw-output`
 if [[ "$status" = "SUCCEEDED" ]]; then
  echo "Job Successfully completed"
  exit
fi
sleep 10
 i=`expr $i + 1`
done

echo "Job is running more than 900 Secs. Please check the status in console"